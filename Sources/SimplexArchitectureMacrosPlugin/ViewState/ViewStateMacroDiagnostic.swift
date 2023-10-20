import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public enum ViewStateMacroDiagnostic {
    case requiresStructOrClass
    case invalidArgument
}

extension ViewStateMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStructOrClass:
            return "'ViewState' macro can only be applied to struct or class"
        case .invalidArgument:
            return "invalid arguments"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "ViewState.\(self)")
    }
}

public extension ViewStateMacro {
    static func diagnoseDeclaration(
        attachedTo declaration: some DeclGroupSyntax
    ) throws {
        guard declaration.as(StructDeclSyntax.self) == nil,
              declaration.as(ClassDeclSyntax.self) == nil
        else {
            return
        }

        if let tokenName = declaration.hasName?.name {
            throw DiagnosticsError(
                diagnostics: [
                    ViewStateMacroDiagnostic
                        .requiresStructOrClass
                        .diagnose(at: tokenName),
                ]
            )
        } else {
            throw DiagnosticsError(
                diagnostics: [
                    ViewStateMacroDiagnostic
                        .requiresStructOrClass
                        .diagnose(at: declaration),
                ]
            )
        }
    }
}
