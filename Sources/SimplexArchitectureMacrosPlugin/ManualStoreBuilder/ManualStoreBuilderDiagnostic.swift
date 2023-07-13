import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ManualStoreBuilderMacroDiagnostic {
    case requiresStruct
    case invalidArgument
}

extension ManualStoreBuilderMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
            return "'StoreBuilder' macro can only be applied to struct"

        case .invalidArgument:
            return "invalid arguments"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "ManualStoreBuilderMacro.\(self)")
    }
}

public extension ManualStoreBuilder {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> (StructDeclSyntax, String)? {
        guard case let .argumentList(arguments) = attribute.argument,
              let firstArgument = arguments.first,
              let type = firstArgument.expression.as(MemberAccessExprSyntax.self)?.base?.as(IdentifierExprSyntax.self)?.identifier.text
        else {
            context.diagnose(ManualStoreBuilderMacroDiagnostic.invalidArgument.diagnose(at: attribute))
            return nil
        }

        if let structDecl = declaration.as(StructDeclSyntax.self)
        {
            return (structDecl, type)
        } else {
            context.diagnose(ManualStoreBuilderMacroDiagnostic.requiresStruct.diagnose(at: attribute))
            return nil
        }
    }
}
