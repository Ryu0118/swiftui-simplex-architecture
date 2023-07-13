import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ReducerBuilderMacroDiagnostic {
    case requiresStruct
    case invalidArgument
}

extension ReducerBuilderMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
            return "'StateBuilder' macro can only be applied to struct"

        case .invalidArgument:
            return "invalid arguments"
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "StoreBuilder.\(self)")
    }
}

public extension ReducerBuilderMacro {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> (StructDeclSyntax, String)? {
        guard case let .argumentList(arguments) = attribute.argument,
              let firstElement = arguments.first
        else {
            context.diagnose(ReducerBuilderMacroDiagnostic.invalidArgument.diagnose(at: attribute))
            return nil
        }

        if let structDecl = declaration.as(StructDeclSyntax.self),
           let stringLiteral = firstElement.expression.as(StringLiteralExprSyntax.self),
           let typeName = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
        {
            return (structDecl, typeName)
        } else {
            context.diagnose(ReducerBuilderMacroDiagnostic.requiresStruct.diagnose(at: attribute))
            return nil
        }
    }
}
