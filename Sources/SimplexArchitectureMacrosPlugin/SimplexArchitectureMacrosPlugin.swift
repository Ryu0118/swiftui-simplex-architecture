#if canImport(SwiftCompilerPlugin)
    import SwiftCompilerPlugin
    import SwiftSyntaxMacros

    @main
    struct SimplexArchitectureMacrosPlugin: CompilerPlugin {
        let providingMacros: [Macro.Type] = [
            ViewStateMacro.self,
            ReducerMacro.self
        ]
    }
#endif
