import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum StoreBuilderMacroDiagnostic {
    case requiresStruct
    case invalidArgument
    case dynamicArgument
}

extension StoreBuilderMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
            return "'StoreBuilder' macro can only be applied to struct"

        case .invalidArgument:
            return "invalid arguments"

        case .dynamicArgument:
            return "Reducer type cannot be inferred from the argument. Please try to call Reducer's initializer directly for the argument"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "StoreBuilder.\(self)")
    }
}

public extension StoreBuilder {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> (StructDeclSyntax, String, String)? {
        guard case let .argumentList(arguments) = attribute.argument,
              let firstArgument = arguments.first
        else {
            context.diagnose(StoreBuilderMacroDiagnostic.invalidArgument.diagnose(at: attribute))
            return nil
        }

        guard let functionCallExpr = firstArgument.expression.as(FunctionCallExprSyntax.self),
              let type = functionCallExpr.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text
        else {
            context.diagnose(StoreBuilderMacroDiagnostic.dynamicArgument.diagnose(at: attribute))
            return nil
        }

        if let structDecl = declaration.as(StructDeclSyntax.self)
        {
            return (structDecl, functionCallExpr.description, type)
        } else {
            context.diagnose(StoreBuilderMacroDiagnostic.requiresStruct.diagnose(at: attribute))
            return nil
        }
    }
}
