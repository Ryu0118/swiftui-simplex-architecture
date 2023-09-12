#if canImport(SwiftCompilerPlugin)
    import SwiftCompilerPlugin
    import SwiftSyntaxMacros

    @main
    struct SimplexArchitectureMacrosPlugin: CompilerPlugin {
        let providingMacros: [Macro.Type] = [
            ScopeState.self,
        ]
    }
#endif
