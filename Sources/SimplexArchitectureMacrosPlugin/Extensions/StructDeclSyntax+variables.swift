import SwiftSyntax

extension DeclGroupSyntax {
    var variables: [VariableDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
}
