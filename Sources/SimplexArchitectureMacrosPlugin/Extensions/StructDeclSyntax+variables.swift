import SwiftSyntax

extension StructDeclSyntax {
    var variables: [VariableDeclSyntax] {
        self
            .memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
}

