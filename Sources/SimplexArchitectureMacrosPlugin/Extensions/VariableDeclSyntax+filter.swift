import SwiftSyntax

extension [VariableDeclSyntax] {
    func filter(propertyWrappers: [String]) -> Self {
        filter {
            $0.attributes.compactMap { $0.as(AttributeSyntax.self) }
                .contains {
                    propertyWrappers.contains($0.attributeName.trimmed.description)
                }
        }
    }
}
