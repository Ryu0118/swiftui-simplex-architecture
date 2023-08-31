import SwiftSyntax

extension DeclGroupSyntax {
    var name: String? {
        switch self {
        case let structDecl as StructDeclSyntax:
            return structDecl.name.text
        case let classDecl as ClassDeclSyntax:
            return classDecl.name.text
        default:
            return nil
        }
    }
}
