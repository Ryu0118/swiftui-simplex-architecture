import SwiftSyntax

protocol HasName: DeclSyntaxProtocol {
    var name: TokenSyntax { get }
}

extension MemberBlockItemListSyntax.Element {
    var hasName: (any HasName)? {
        if let enumDecl = decl.as(EnumDeclSyntax.self) {
            enumDecl
        } else if let structDecl = decl.as(StructDeclSyntax.self) {
            structDecl
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            classDecl
        } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
            actorDecl
        } else {
            nil
        }
    }
}

extension DeclGroupSyntax {
    var hasName: (any HasName)? {
        if let enumDecl = `as`(EnumDeclSyntax.self) {
            enumDecl
        } else if let structDecl = `as`(StructDeclSyntax.self) {
            structDecl
        } else if let classDecl = `as`(ClassDeclSyntax.self) {
            classDecl
        } else if let actorDecl = `as`(ActorDeclSyntax.self) {
            actorDecl
        } else if let protocolDecl = `as`(ProtocolDeclSyntax.self) {
            protocolDecl
        } else {
            nil
        }
    }
}

extension StructDeclSyntax: HasName {}
extension ClassDeclSyntax: HasName {}
extension ActorDeclSyntax: HasName {}
extension EnumDeclSyntax: HasName {}
extension ProtocolDeclSyntax: HasName {}
