import SwiftSyntax

extension DeclModifierListSyntax {
    var accessModifier: String {
        let accessModifiers = [
            "open", "public", "package", "internal",
            "fileprivate", "private",
        ]
        return compactMap { $0.as(DeclModifierSyntax.self)?.name.text }
            .filter { accessModifiers.contains($0 ?? "") }.first?
            .map {
                if $0 == "fileprivate" || $0 == "private" {
                    "internal"
                } else {
                    $0
                }
            } ?? ""
    }
}
