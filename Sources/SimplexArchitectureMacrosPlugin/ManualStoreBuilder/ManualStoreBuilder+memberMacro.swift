import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

fileprivate extension VariableDeclSyntax {
    var variableName: String? {
        bindings.first?.pattern.trimmed.description
    }
}

public struct ManualStoreBuilder: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax, Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let (structDecl, reducerType) = decodeExpansion(of: node, attachedTo: declaration, in: context) else {
            return []
        }

        let variables = declaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }

        let stateVariables = variables
            .filter {
                $0.attributes?
                    .compactMap { $0.as(AttributeSyntax.self) }
                    .contains {
                        $0.attributeName.trimmed.description == "State" ||
                        $0.attributeName.trimmed.description == "Binding" ||
                        $0.attributeName.trimmed.description == "ObservableState" ||
                        $0.attributeName.trimmed.description == "ObservedObject" ||
                        $0.attributeName.trimmed.description == "StateObject" ||
                        $0.attributeName.trimmed.description == "FocusState"
                    } ?? false
            }
            .filter { $0.variableName != "store" && $0.variableName != "_store" }
            .map { $0.with(\.attributes, []) }

        var keyPathPairs = stateVariables
            .compactMap(\.variableName)
            .map {
                "\\.\($0): \\.\($0)"
            }
            .joined(separator: ", ")

        keyPathPairs = if keyPathPairs.isEmpty {
            ":"
        } else {
            keyPathPairs
        }

        let structName = structDecl.identifier.text
        let modifier = structDecl.modifiers?.compactMap { $0.as(DeclModifierSyntax.self)?.name.text }.first ?? "internal"

        return [
            DeclSyntax(
                "\(raw: modifier) typealias Reducer = \(raw: reducerType)"
            ),
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .identifier(modifier))],
                    identifier: "States",
                    inheritanceClause: TypeInheritanceClauseSyntax {
                        InheritedTypeSyntax(typeName: TypeSyntax(stringLiteral: "StatesProtocol"))
                    }
                ) {
                    MemberDeclListSyntax(stateVariables.map { MemberDeclListItemSyntax(decl: $0) })
                    MemberDeclListSyntax {
                        MemberDeclListItemSyntax(
                            decl: DeclSyntax(
                                "\(raw: modifier) static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<\(raw: structName)>] = [\(raw: keyPathPairs)]"
                            )
                        )
                    }
                }
            )
        ]
    }
}
