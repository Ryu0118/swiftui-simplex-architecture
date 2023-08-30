#if canImport(SwiftCompilerPlugin)
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct SimplexArchitectureMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ReducerBuilderMacro.self,
        ManualStoreBuilder.self
    ]
}
#endif
