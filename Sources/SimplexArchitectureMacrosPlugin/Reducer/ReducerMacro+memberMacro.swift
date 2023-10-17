import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ReducerMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic.notStruct.diagnose(at: declaration)
                ]
            )
        }

        let reducerAccessModifier = declaration.modifiers.accessModifier

        try declaration.memberBlock.members
            .compactMap { $0.decl.as(TypeAliasDeclSyntax.self) }
            .forEach { typealiasDecl in
                switch typealiasDecl.name.text {
                case "ViewAction", "ReducerAction":
                    throw DiagnosticsError(
                        diagnostics: [
                            ReducerMacroDiagnostic
                                .typealiasCannotBeUsed(name: typealiasDecl.name.text)
                                .diagnose(at: typealiasDecl.name)
                        ]
                    )
                default: break
                }
            }

        var viewAction: EnumDeclSyntax?
        var reducerAction: EnumDeclSyntax?

        declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumDeclSyntax.self) }
            .forEach { enumDecl in
                switch enumDecl.name.text {
                case "ViewAction":
                    viewAction = enumDecl
                case "ReducerAction":
                    reducerAction = enumDecl
                default: break
                }
            }

        guard let viewAction else {
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic
                        .cannotFindViewAction(reducer: structDecl.name.text)
                        .diagnose(at: structDecl)
                ]
            )
        }

        let modifiedViewAction = changeDeclToTypealias(action: viewAction, reducerAccessModifier: reducerAccessModifier)
        let modifiedReducerAction: [MemberBlockItemListSyntax.Element] = if let reducerAction {
            changeDeclToTypealias(action: reducerAction, reducerAccessModifier: reducerAccessModifier)
        } else {
            []
        }

        if let reducerAction,
           let viewActionInheritance = reducerAction.inheritanceClause, 
           Set(viewAction.inheritedTypes) != Set(reducerAction.inheritedTypes)
        {
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic
                        .noMatchInheritanceClause
                        .diagnose(at: viewActionInheritance)
                ]
            )
        }

        let allCases = viewAction.cases + (reducerAction?.cases ?? [])
        let viewActionCaseElements = viewAction.caseElements
        let reducerActionCaseElements = reducerAction?.caseElements ?? []
        let caseElements = viewActionCaseElements + reducerActionCaseElements

        try caseElements.duplicates().forEach { duplicateElement in
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic
                        .duplicatedCase
                        .diagnose(at: duplicateElement)
                ]
            )
        }

        let viewActionToAction = if !viewActionCaseElements.isEmpty {
            """
            switch viewAction {
            \(mapToAction(from: viewAction))
            }
            """
        } else {
            "fatalError()"
        }
        let reducerActionToAction = if let reducerAction, !reducerActionCaseElements.isEmpty {
            """
            switch reducerAction {
            \(mapToAction(from: reducerAction))
            }
            """
        } else {
            "fatalError()"
        }

        let reducerNeverAction: DeclSyntax? = if reducerAction == nil {
            DeclSyntax(
               EnumDeclSyntax(
                   modifiers: [DeclModifierSyntax(name: .identifier(reducerAccessModifier))],
                   name: .identifier("ReducerAction")
               ) {}
           )
        } else {
            nil
        }

        return [
            reducerNeverAction,
            DeclSyntax(
                EnumDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .identifier(reducerAccessModifier))],
                    name: .identifier("Action"),
                    inheritanceClause: InheritanceClauseSyntax {
                        (viewAction.inheritanceClause?.inheritedTypes ?? []) + 
                        [InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "ActionProtocol"))]
                    }
                ) {
                    MemberBlockItemListSyntax {
                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                """
                                \(raw: modifiedViewAction.map(\.description).joined())
                                \(raw: modifiedReducerAction.map(\.description).joined())
                                """
                            )
                        )

                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                """
                                \(raw: reducerAccessModifier) init(viewAction: ViewAction) {
                                    \(raw: viewActionToAction)
                                }
                                """
                            ).formatted().cast(DeclSyntax.self)
                        )

                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                """
                                \(raw: reducerAccessModifier) init(reducerAction: ReducerAction) {
                                    \(raw: reducerActionToAction)
                                }
                                """
                            ).formatted().cast(DeclSyntax.self)
                        )
                    }
                }
            )
        ].compactMap { $0 }
    }

    private static func changeDeclToTypealias(action: EnumDeclSyntax, reducerAccessModifier: String) -> [MemberBlockItemListSyntax.Element] {
        action.memberBlock.members.compactMap {
            if let enumDecl = $0.decl.as(EnumDeclSyntax.self),
               !enumDecl.name.text.contains(action.name.text)
            {
                $0.with(
                    \.decl,
                     """
                     \n\(raw: reducerAccessModifier) typealias \(raw: enumDecl.name.text) = \(raw: action.name.text).\(raw: enumDecl.name.text)
                     """
                )
            } else if let structDecl = $0.decl.as(StructDeclSyntax.self),
                      !structDecl.name.text.contains(action.name.text)
            {
                $0.with(
                    \.decl,
                     """
                     \n\(raw: reducerAccessModifier) typealias \(raw: structDecl.name.text) = \(raw: action.name.text).\(raw: structDecl.name.text)
                     """
                )
            } else if let classDecl = $0.decl.as(ClassDeclSyntax.self),
                      !classDecl.name.text.contains(action.name.text)
            {
                $0.with(
                    \.decl,
                     """
                     \n\(raw: reducerAccessModifier) typealias \(raw: classDecl.name.text) = \(raw: action.name.text).\(raw: classDecl.name.text)
                     """
                )
            } else if let actorDecl = $0.decl.as(ActorDeclSyntax.self),
                      !actorDecl.name.text.contains(action.name.text)
            {
                $0.with(
                    \.decl,
                     """
                     \n\(raw: reducerAccessModifier) typealias \(raw: actorDecl.name.text) = \(raw: action.name.text).\(raw: actorDecl.name.text)
                     """
                )
            } else {
                $0
            }
        }
    }

    private static func mapToAction(from enumDecl: EnumDeclSyntax) -> String {
        enumDecl.caseElements.map { caseElement in
            if let parameters = caseElement.parameterClause?.parameters.compactMap({ $0.as(EnumCaseParameterSyntax.self) }) {
                let argumentNames = parameters.argumentNames
                let variables = argumentNames
                    .map { "let \($0)" }
                    .joined(separator: ", ")
                let arguments = zip(parameters, argumentNames).map { parameter, argumentName in
                    if let firstName = parameter.firstName?.text {
                        "\(firstName): \(argumentName)"
                    } else {
                        "\(argumentName)"
                    }
                }.joined(separator: ", ")
                return """
                case .\(caseElement.name.text)(\(variables)):
                    self = .\(caseElement.name.text)(\(arguments))
                """
            } else {
                return """
                case .\(caseElement.name.text):
                    self = .\(caseElement.name.text)
                """
            }
        }.joined(separator: "\n")
    }
}

private extension [EnumCaseParameterSyntax] {
    var argumentNames: [String] {
        enumerated().map { index, parameter in
            parameter.firstName?.text ?? "arg\(index + 1)"
        }
    }
}

private extension EnumDeclSyntax {
    var cases: [EnumCaseDeclSyntax] {
        memberBlock.members
            .compactMap { $0.as(MemberBlockItemSyntax.self)?.decl.as(EnumCaseDeclSyntax.self) }
    }

    var caseElements: [EnumCaseElementSyntax] {
        cases.flatMap(\.caseElements)
    }
}

private extension EnumCaseDeclSyntax {
    var caseElements: [EnumCaseElementSyntax] {
        elements.compactMap { $0.as(EnumCaseElementSyntax.self) }
    }
}

private extension [EnumCaseElementSyntax] {
    func duplicates() -> [EnumCaseElementSyntax] {
        var map: [String: EnumCaseElementSyntax] = [:]
        var counts: [String: Int] = [:]

        for item in self {
            counts[item.trimmedDescription, default: 0] += 1
            map[item.trimmedDescription] = item
        }

        return counts.filter { $1 > 1 }.compactMap { map[$0.key] }
    }
}

private extension EnumDeclSyntax {
    var inheritedTypes: [String] {
        inheritanceClause?.inheritedTypes
            .compactMap {
                $0.as(InheritedTypeSyntax.self)?.type
                    .as(IdentifierTypeSyntax.self)?
                    .name.text
            } ?? []
    }
}

protocol HasName: DeclSyntaxProtocol {
    var name: TokenSyntax { get }
}

extension StructDeclSyntax: HasName {}
extension ClassDeclSyntax: HasName {}
extension ActorDeclSyntax: HasName {}
extension EnumDeclSyntax: HasName {}
