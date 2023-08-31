import SwiftSyntax
import SwiftSyntaxMacros

extension ScopeState: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard decodeExpansion(of: node, attachedTo: declaration, in: context) else {
            return []
        }

        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "ActionSendable" }) {
            return []
        }
        let declSyntax: DeclSyntax =
            """
            extension \(type.trimmed): ActionSendable {}
            """
        return [
            declSyntax.cast(ExtensionDeclSyntax.self)
        ]
    }
}
