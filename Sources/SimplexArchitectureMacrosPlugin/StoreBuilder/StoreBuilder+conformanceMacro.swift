import SwiftSyntax
import SwiftSyntaxMacros

extension StoreBuilder: ConformanceMacro {
    public static func expansion<Declaration, Context>(
        of node: AttributeSyntax,
        providingConformancesOf declaration: Declaration,
        in context: Context
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)]
    where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypeCollection,
           inheritedTypes.contains(where: { inherited in inherited.typeName.trimmedDescription == "SimplexStoreBuilder" }) {
            return []
        }
        return [("SimplexStoreBuilder", nil)]
    }
}
