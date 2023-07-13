import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct ReducerBuilderMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax, Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let (structDecl, typeName) = decodeExpansion(of: node, attachedTo: declaration, in: context) else {
            return []
        }

        let modifier = structDecl.modifiers?.compactMap { $0.as(DeclModifierSyntax.self)?.name.text }.first ?? "internal"

        return [
            DeclSyntax(
                "\(raw: modifier) typealias State = StateContainer<\(raw: typeName)>"
            ),
            DeclSyntax(
                "\(raw: modifier) typealias Target = \(raw: typeName)"
            )
        ]
    }
}
