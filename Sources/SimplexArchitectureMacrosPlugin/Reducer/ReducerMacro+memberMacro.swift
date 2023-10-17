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

        var viewAction: EnumDeclSyntax?
        var reducerAction: EnumDeclSyntax?

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

        return [
            DeclSyntax(
                EnumDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .identifier(reducerAccessModifier))],
                    name: .identifier("Action"),
                    inheritanceClause: viewAction.inheritanceClause
                ) {
                    MemberBlockItemListSyntax {
                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                """
                                \(raw: allCases.map(\.description).joined())
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
        ]
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

extension DeclModifierListSyntax {
    var accessModifier: String {
        let accessModifiers = [
            "open", "public", "package", "internal",
            "fileprivate", "private"
        ]
        return compactMap { $0.as(DeclModifierSyntax.self)?.name.text }
            .filter { accessModifiers.contains($0 ?? "") }.first?
            .map {
                if $0 == "fileprivate" || $0 == "private" {
                    "internal"
                } else {
                    $0
                }
            } ?? ""
    }
}

extension [EnumCaseParameterSyntax] {
    var argumentNames: [String] {
        enumerated().map { index, parameter in
            parameter.firstName?.text ?? "arg\(index + 1)"
        }
    }
}

extension EnumDeclSyntax {
    var cases: [EnumCaseDeclSyntax] {
        memberBlock.members
            .compactMap { $0.as(MemberBlockItemSyntax.self)?.decl.as(EnumCaseDeclSyntax.self) }
    }

    var caseElements: [EnumCaseElementSyntax] {
        cases.flatMap(\.caseElements)
    }
}

extension EnumCaseDeclSyntax {
    var caseElements: [EnumCaseElementSyntax] {
        elements.compactMap { $0.as(EnumCaseElementSyntax.self) }
    }
}

extension [EnumCaseElementSyntax] {
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

extension EnumDeclSyntax {
    var inheritedTypes: [String] {
        inheritanceClause?.inheritedTypes
            .compactMap {
                $0.as(InheritedTypeSyntax.self)?.type
                    .as(IdentifierTypeSyntax.self)?
                    .name.text
            } ?? []
    }
}

//extension Array where Element: Hashable {
//    func duplicates() -> [Element] {
//        var counts: [Element: Int] = [:]
//        for item in self {
//            counts[item, default: 0] += 1
//        }
//
//        return counts.filter { $1 > 1 }.map { $0.key }
//    }
//}

enum Action {
    case hoge

    init(from: Never) {
        fatalError()
    }
}
