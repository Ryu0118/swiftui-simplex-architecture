#if canImport(SwiftCompilerPlugin)
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct SimplexArchitectureMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StoreBuilder.self,
        ReducerBuilderMacro.self,
        ManualStoreBuilder.self
    ]
}
#endif
