import SwiftSyntax

extension VariableDeclSyntax {
    var variableName: String? {
        bindings.first?.pattern.trimmed.description
    }
}
