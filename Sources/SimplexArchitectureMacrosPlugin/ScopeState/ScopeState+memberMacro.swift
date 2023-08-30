import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct ScopeState: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax, Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let structDecl = decodeExpansion(of: node, attachedTo: declaration, in: context) else {
            return []
        }

        // SwiftUI's propertyWrapper
        let detecting = [
            "State",
            "Binding",
            "ObservableState",
            "ObservedObject",
            "StateObject",
            "FocusState",
            "EnvironmentObject",
            "GestureState",
            "AppStorage"
        ]

        let stateVariables = structDecl.variables
            .filter(propertyWrappers: detecting)
            .map { $0.with(\.attributes, []).with(\.modifiers, []) }

        let keyPathPairs = structDecl.variables
            .filter(propertyWrappers: detecting)
            .map { $0.with(\.attributes, []).with(\.modifiers, []) }
            .compactMap(\.variableName)
            .map { "\\.\($0): \\.\($0)" }
            .joined(separator: ", ")
            .modifying {
                if $0.isEmpty {
                    ":"
                } else {
                    $0
                }
            }

        let modifier = structDecl.modifiers.compactMap {
            $0.as(DeclModifierSyntax.self)?.name.text
        }.first ?? "internal"

        return [
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .identifier(modifier))],
                    name: "States",
                    inheritanceClause: InheritanceClauseSyntax {
                        InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "StatesProtocol"))
                    }
                ) {
                    MemberBlockItemListSyntax(stateVariables.map { MemberBlockItemSyntax(decl: $0) })
                    MemberBlockItemListSyntax {
                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                "\(raw: modifier) static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<\(raw: structDecl.name.text)>] = [\(raw: keyPathPairs)]"
                            )
                        )
                    }
                }
            )
        ]
    }
}
