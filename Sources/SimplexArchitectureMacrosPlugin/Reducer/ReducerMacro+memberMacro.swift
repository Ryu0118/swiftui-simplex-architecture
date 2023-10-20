import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ReducerMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of _: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in _: Context
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic.notStruct.diagnose(at: declaration),
                ]
            )
        }

        try diagnosticTypealias(of: structDecl)
        let (viewAction, reducerAction) = try getActions(of: structDecl)
        let reducerAccessModifier = declaration.modifiers.accessModifier

        let modifiedViewAction = changeAnyNestedDeclToTypealias(
            action: viewAction,
            reducerAccessModifier: reducerAccessModifier
        )

        let modifiedReducerAction: EnumDeclSyntax = if let reducerAction {
            changeAnyNestedDeclToTypealias(
                action: reducerAction,
                reducerAccessModifier: reducerAccessModifier
            )
        } else {
            EnumDeclSyntax(
                modifiers: [DeclModifierSyntax(name: .identifier(reducerAccessModifier))],
                name: .identifier("ReducerAction")
            ) {}
        }

        let viewActionToAction = mapToActionInitializer(
            from: viewAction,
            switchTarget: "viewAction",
            accessModifier: reducerAccessModifier
        )
        let reducerActionToAction = mapToActionInitializer(
            from: reducerAction,
            switchTarget: "reducerAction",
            accessModifier: reducerAccessModifier
        )

        let emptyReducerAction: DeclSyntax? = if reducerAction == nil {
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
            emptyReducerAction,
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
                        // case
                        DeclSyntax(
                            """
                            \(raw: modifiedViewAction.memberBlock.members
                                .map(\.description)
                                .joined())
                            \(raw: modifiedReducerAction.memberBlock.members
                                .map(\.description)
                                .joined())
                            """
                        )

                        viewActionToAction
                        reducerActionToAction
                    }
                }
                    .formatted().cast(EnumDeclSyntax.self)
            ).formatted().cast(DeclSyntax.self),
        ].compactMap { $0 }
    }

    private static func diagnosticTypealias(of structDecl: StructDeclSyntax) throws {
        try structDecl.memberBlock.members
            .compactMap { $0.decl.as(TypeAliasDeclSyntax.self) }
            .forEach { typealiasDecl in
                switch typealiasDecl.name.text {
                case "ViewAction", "ReducerAction":
                    throw DiagnosticsError(
                        diagnostics: [
                            ReducerMacroDiagnostic
                                .typealiasCannotBeUsed(name: typealiasDecl.name.text)
                                .diagnose(at: typealiasDecl.name),
                        ]
                    )
                default: break
                }
            }
    }

    private static func getActions(
        of structDecl: StructDeclSyntax
    ) throws -> (viewAction: EnumDeclSyntax, reducerAction: EnumDeclSyntax?) {
        var viewAction: EnumDeclSyntax?
        var reducerAction: EnumDeclSyntax?

        try structDecl.memberBlock.members
            .forEach {
                guard let hasName = $0.hasName else {
                    return
                }

                let name = hasName.name.text

                if let enumDecl = $0.decl.as(EnumDeclSyntax.self) {
                    switch name {
                    case "ViewAction":
                        viewAction = enumDecl
                    case "ReducerAction":
                        reducerAction = enumDecl
                    default: return
                    }
                } else if name == "ViewAction" || name == "ReducerAction" {
                    // ViewAction and ReducerAction must be enum
                    throw DiagnosticsError(
                        diagnostics: [
                            ReducerMacroDiagnostic
                                .actionMustBeEnum(actionName: name)
                                .diagnose(at: hasName),
                        ]
                    )
                }
            }

        // ViewAction must not be nil
        guard let viewAction else {
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic
                        .cannotFindViewAction(reducer: structDecl.name.text)
                        .diagnose(at: structDecl),
                ]
            )
        }

        // The Inheritance clause must be equal between ViewAction and ReducerAction
        if let reducerAction,
           Set(viewAction.inheritedTypes) != Set(reducerAction.inheritedTypes)
        {
            if let inheritanceClause = reducerAction.inheritanceClause {
                throw DiagnosticsError(
                    diagnostics: [
                        ReducerMacroDiagnostic
                            .noMatchInheritanceClause
                            .diagnose(at: inheritanceClause),
                    ]
                )
            } else {
                throw DiagnosticsError(
                    diagnostics: [
                        ReducerMacroDiagnostic
                            .noMatchInheritanceClause
                            .diagnose(at: reducerAction),
                    ]
                )
            }
        }

        let viewActionCaseElements = viewAction.caseElements
        let reducerActionCaseElements = reducerAction?.caseElements ?? []
        let caseElements = viewActionCaseElements + reducerActionCaseElements

        // Enum cases can be overloaded, but cases with the same arguments cannot be overloaded.
        try caseElements.duplicates().forEach { duplicateElement in
            throw DiagnosticsError(
                diagnostics: [
                    ReducerMacroDiagnostic
                        .duplicatedCase
                        .diagnose(at: duplicateElement),
                ]
            )
        }

        return (viewAction, reducerAction)
    }

    private static func changeAnyNestedDeclToTypealias(action: EnumDeclSyntax, reducerAccessModifier: String) -> EnumDeclSyntax {
        action.with(
            \.memberBlock,
             action.memberBlock.with(
                \.members,
                 MemberBlockItemListSyntax(
                    action.memberBlock.members.compactMap {
                        if let name = $0.hasName?.name.text,
                           !name.contains(action.name.text)
                        {
                            $0.with(
                                \.decl,
                                 DeclSyntax(
                                    TypeAliasDeclSyntax(
                                        modifiers: .init(arrayLiteral: DeclModifierSyntax(name: .identifier(reducerAccessModifier))),
                                        name: .identifier(name),
                                        initializer: TypeInitializerClauseSyntax(
                                            value: IdentifierTypeSyntax(name: .identifier("\(action.name.text).\(name)"))
                                        )
                                    )
                                 )
                            )
                        } else {
                            $0
                        }
                    }
                 )
             )
             .formatted()
             .cast(MemberBlockSyntax.self)
        )
    }

    private static func mapToActionInitializer(
        from enumDecl: EnumDeclSyntax?,
        switchTarget: String,
        accessModifier: String
    ) -> InitializerDeclSyntax {
        let cases = enumDecl?.caseElements.map { caseElement in
            if let parameters = caseElement.parameterClause?.parameters.compactMap({ $0.as(EnumCaseParameterSyntax.self) }) {
                let argumentNames = parameters.enumerated().map { index, parameter in
                    parameter.firstName?.text ?? "arg\(index + 1)"
                }
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

        return InitializerDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .identifier(accessModifier))
            },
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax {
                    FunctionParameterSyntax(
                        firstName: .identifier(switchTarget),
                        type: IdentifierTypeSyntax(name: .identifier(enumDecl?.name.text ?? "ReducerAction"))
                    )
                }
            ),
            body: CodeBlockSyntax {
                if let cases, let enumDecl, !enumDecl.caseElements.isEmpty {
                    """
                    switch \(raw: switchTarget) {
                    \(raw: cases)
                    }
                    """
                } else {
                    "fatalError()"
                }
            }
        )
        .formatted()
        .cast(InitializerDeclSyntax.self)
    }
}

private extension EnumDeclSyntax {
    var cases: [EnumCaseDeclSyntax] {
        memberBlock.members
            .compactMap {
                $0.as(MemberBlockItemSyntax.self)?.decl.as(EnumCaseDeclSyntax.self)
            }
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
            if let parameterClause = item.parameterClause, parameterClause.parameters.compactMap(\.firstName).isEmpty
            {
                /*
                 public enum ViewAction {
                     case increment
                 }
                 public enum ReducerAction {
                     case increment(Int)
                          ┬────────
                          ╰─ 🛑 Cannot have duplicate cases in ViewAction and ReducerAction
                 }
                 */
                let noAssociatedValueCase = item.with(\.parameterClause, nil)
                counts[noAssociatedValueCase.trimmedDescription, default: 0] += 1
                map[noAssociatedValueCase.trimmedDescription] = noAssociatedValueCase
            } else {
                counts[item.trimmedDescription, default: 0] += 1
                map[item.trimmedDescription] = item
            }
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
