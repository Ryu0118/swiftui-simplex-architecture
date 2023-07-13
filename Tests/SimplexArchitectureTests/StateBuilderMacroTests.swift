#if canImport(SimplexArchitectureMacrosPlugin)
import XCTest
import SimplexArchitecture
import SimplexArchitectureMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

final class StateBuilderMacroTests: XCTestCase {
    let macros: [String: Macro.Type] = [
        "StoreBuilder": StoreBuilder.self
    ]

    func testMacro() throws {
        assertMacroExpansion(
            """
            @StoreBuilder(reducer: TestReducer())
            struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String

                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """

            struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String

                var body: some View {
                    EmptyView()
                }
                internal let store = Store(reducer: TestReducer())
                internal struct States: StatesProtocol {
                    var testState: Int = 0
                    var testBinding: String
                    internal static var keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] {
                        [\\.testState: \\.testState, \\.testBinding: \\.testBinding]
                    }
                }
            }
            """,
            macros: macros
        )

        assertMacroExpansion(
            """
            @StoreBuilder(reducer: TestReducer())
            struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String
                var hoge = 0
                var fuga = 0

                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """

            struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String
                var hoge = 0
                var fuga = 0

                var body: some View {
                    EmptyView()
                }
                internal let store = Store(reducer: TestReducer())
                internal struct States: StatesProtocol {
                    var testState: Int = 0
                    var testBinding: String
                    internal static var keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] {
                        [\\.testState: \\.testState, \\.testBinding: \\.testBinding]
                    }
                }
            }
            """,
            macros: macros
        )

        assertMacroExpansion(
            """
            @StoreBuilder(reducer: TestReducer())
            public struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String
                var hoge = 0
                var fuga = 0

                public var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """

            public struct TestView: View {
                @State var testState: Int = 0
                @Binding var testBinding: String
                var hoge = 0
                var fuga = 0

                public var body: some View {
                    EmptyView()
                }
                public let store = Store(reducer: TestReducer())
                public struct States: StatesProtocol {
                    var testState: Int = 0
                    var testBinding: String
                    public static var keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] {
                        [\\.testState: \\.testState, \\.testBinding: \\.testBinding]
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
#endif
