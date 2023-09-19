import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

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
            return "'ScopeState' macro can only be applied to struct or class"
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
        of syntax: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> Bool {
        if declaration.as(StructDeclSyntax.self) != nil || declaration.as(ClassDeclSyntax.self) != nil {
            return true
        } 
        else if declaration.as(ActorDeclSyntax.self) != nil
            || declaration.as(ProtocolDeclSyntax.self) != nil
            || declaration.as(ExtensionDeclSyntax.self) != nil
        {
            context.diagnose(ScopeStateMacroDiagnostic.requiresStructOrClass.diagnose(at: syntax))
        }
        return false
    }
}
