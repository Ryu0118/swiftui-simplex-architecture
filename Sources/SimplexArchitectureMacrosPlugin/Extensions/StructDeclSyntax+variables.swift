import SwiftSyntax

extension DeclGroupSyntax {
    var variables: [VariableDeclSyntax] {
        self.memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
}

