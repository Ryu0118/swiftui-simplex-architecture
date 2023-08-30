import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ScopedStateMacroDiagnostic {
    case requiresStruct
    case invalidArgument
}

extension ScopedStateMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
            return "'ScopedState' macro can only be applied to struct"

        case .invalidArgument:
            return "invalid arguments"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "ScopedStateMacro.\(self)")
    }
}

public extension ScopedState {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> StructDeclSyntax? {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(ScopedStateMacroDiagnostic.requiresStruct.diagnose(at: attribute))
            return nil
        }
        return structDecl
    }
}
