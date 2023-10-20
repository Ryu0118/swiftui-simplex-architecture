import SwiftSyntax
import SwiftSyntaxMacros

extension ViewStateMacro: ExtensionMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        try diagnoseDeclaration(attachedTo: declaration)

        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { inherited in
               inherited.type.trimmedDescription == "ActionSendable"
           })
        {
            return []
        }
        let declSyntax: DeclSyntax =
            """
            extension \(type.trimmed): ActionSendable {}
            """
        return [
            declSyntax.cast(ExtensionDeclSyntax.self),
        ]
    }
}
