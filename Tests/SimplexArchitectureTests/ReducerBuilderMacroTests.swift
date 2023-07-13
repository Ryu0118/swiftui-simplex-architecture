#if canImport(SimplexArchitectureMacrosPlugin)
import XCTest
import SimplexArchitecture
import SimplexArchitectureMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

final class ReducerBuilderMacroTests: XCTestCase {
    let macros: [String: Macro.Type] = [
        "Reducer": ReducerBuilderMacro.self
    ]

    func testMacro() throws {
        assertMacroExpansion(
            """
            @Reducer("TestView")
            struct TestReducer {
                enum Action {
                    case test
                }

                func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
                    .none
                }
            }
            """,
            expandedSource: """

            struct TestReducer {
                enum Action {
                    case test
                }

                func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
                    .none
                }
                internal typealias State = StateContainer<TestView>
                internal typealias Target = TestView
            }
            """,
            macros: macros
        )

        assertMacroExpansion(
            """
            @Reducer("TestView")
            public struct TestReducer {
                public enum Action {
                    case test
                }

                public func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
                    .none
                }
            }
            """,
            expandedSource: """

            public struct TestReducer {
                public enum Action {
                    case test
                }

                public func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
                    .none
                }
                public typealias State = StateContainer<TestView>
                public typealias Target = TestView
            }
            """,
            macros: macros
        )
    }
}
#endif
