import SwiftSyntax
import SwiftSyntaxMacros

extension ReducerMacro: ExtensionMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { inherited in
               inherited.type.trimmedDescription == "ReducerProtocol"
           })
        {
            return []
        }
        let declSyntax: DeclSyntax =
            """
            extension \(type.trimmed): ReducerProtocol {}
            """
        return [
            declSyntax.cast(ExtensionDeclSyntax.self),
        ]
    }
}
