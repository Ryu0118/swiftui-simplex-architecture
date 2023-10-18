import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public enum ReducerMacroDiagnostic {
    case typealiasCannotBeUsed(name: String)
    case cannotFindViewAction(reducer: String)
    case notStruct
    case duplicatedCase
    case noMatchInheritanceClause
}

extension ReducerMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case let .typealiasCannotBeUsed(type):
            "\(type) cannot be defined with typealias"

        case let .cannotFindViewAction(reducer):
            "ViewAction not found in \(reducer)"

        case .notStruct:
            "@Reducer can only be applied to struct"

        case .duplicatedCase:
            "Cannot have duplicate cases in ViewAction and ReducerAction"

        case .noMatchInheritanceClause:
            "The inheritance clause must match between ViewAction and ReducerAction"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        switch self {
        case .typealiasCannotBeUsed:
            MessageID(domain: "ReducerMacroDiagnostic", id: "typealiasCannotBeUsed")

        case .cannotFindViewAction:
            MessageID(domain: "ReducerMacroDiagnostic", id: "cannotFindViewAction")

        case .notStruct:
            MessageID(domain: "ReducerMacroDiagnostic", id: "notStruct")

        case .duplicatedCase:
            MessageID(domain: "ReducerMacroDiagnostic", id: "duplicatedCase")

        case .noMatchInheritanceClause:
            MessageID(domain: "ReducerMacroDiagnostic", id: "noMatchInheritanceClause")
        }
    }
}
