import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ScopeStateMacroDiagnostic {
    case requiresStruct
    case invalidArgument
}

extension ScopeStateMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
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
    ) -> StructDeclSyntax? {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(ScopeStateMacroDiagnostic.requiresStruct.diagnose(at: attribute))
            return nil
        }
        return structDecl
    }
}
