import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ViewStateMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard decodeExpansion(of: node, attachedTo: declaration, in: context) else {
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
            "AppStorage",
            "Published",
            "SceneStorage",
        ]

        let viewState = declaration.variables
            .filter(propertyWrappers: detecting)
            .map { $0.with(\.attributes, []).with(\.modifiers, []) }

        let keyPathPairs = viewState
            .compactMap(\.variableName)
            .filter { !$0.isEmpty }
            .map { "\\.\($0): \\.\($0)" }
            .joined(separator: ", ")
            .modifying {
                if $0.isEmpty {
                    ":"
                } else {
                    $0
                }
            }

        let accessModifier = declaration.modifiers.accessModifier

        return [
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .identifier(accessModifier))],
                    name: "ViewState",
                    inheritanceClause: InheritanceClauseSyntax {
                        InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "ViewStateProtocol"))
                    }
                ) {
                    MemberBlockItemListSyntax(viewState.map { MemberBlockItemSyntax(decl: $0) })
                    MemberBlockItemListSyntax {
                        MemberBlockItemSyntax(
                            decl: DeclSyntax(
                                "\(raw: accessModifier) static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<\(raw: declaration.name ?? "")>] = [\(raw: keyPathPairs)]"
                            )
                        )
                    }
                }
            ),
        ]
    }
}
