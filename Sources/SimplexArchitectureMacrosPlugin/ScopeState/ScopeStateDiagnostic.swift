import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ScopeStateMacroDiagnostic {
    case requiresStructOrClass
    case invalidArgument
}

extension ScopeStateMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStructOrClass:
            return "'ScopeState' macro can only be applied to struct"
        case .invalidArgument:
            return "invalid arguments"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "ScopeState.\(self)")
    }
}

public extension ScopeState {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> Bool {
        declaration.as(StructDeclSyntax.self) != nil || declaration.as(ClassDeclSyntax.self) != nil
    }
}
