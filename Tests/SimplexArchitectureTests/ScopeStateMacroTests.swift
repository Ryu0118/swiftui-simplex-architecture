import MacroTesting
@testable import SimplexArchitecture
@testable import SimplexArchitectureMacrosPlugin
import SwiftUI
import XCTest

final class ScopeStateMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: ["ScopeState": ScopeState.self]
        ) {
            super.invokeTest()
        }
    }

    func testDiagnostic() {
        assertMacro {
            """
            @ScopeState
            public actor Test {
            }
            """
        } matches: {
            """
            @ScopeState
            ┬──────────
            ├─ 🛑 'ScopeState' macro can only be applied to struct or class
            ╰─ 🛑 'ScopeState' macro can only be applied to struct or class
            public actor Test {
            }
            """
        }

        assertMacro {
            """
            @ScopeState
            public protocol Test {
            }
            """
        } matches: {
            """
            @ScopeState
            ┬──────────
            ├─ 🛑 'ScopeState' macro can only be applied to struct or class
            ╰─ 🛑 'ScopeState' macro can only be applied to struct or class
            public protocol Test {
            }
            """
        }

        assertMacro {
            """
            @ScopeState
            public extension Test {
            }
            """
        } matches: {
            """
            @ScopeState
            ┬──────────
            ├─ 🛑 'ScopeState' macro can only be applied to struct or class
            ╰─ 🛑 'ScopeState' macro can only be applied to struct or class
            public extension Test {
            }
            """
        }
    }

    func testPublicExpansion() {
        assertMacro {
            """
            @ScopeState
            public struct TestView: View {
                @State var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }
            }
            """
        } matches: {
            #"""
            public struct TestView: View {
                @State var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }

                public struct States: StatesProtocol {
                    var count = 0
                    public static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] = [\.count: \.count]
                }
            }

            extension TestView: ActionSendable {
            }
            """#
        }
    }

    func testInternalExpansion() {
        assertMacro {
            """
            @ScopeState
            struct TestView: View {
                @State var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }
            }
            """
        } matches: {
            #"""
            struct TestView: View {
                @State var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }

                internal struct States: StatesProtocol {
                    var count = 0
                    internal static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] = [\.count: \.count]
                }
            }

            extension TestView: ActionSendable {
            }
            """#
        }
    }

    func testFileprivateExpansion() {
        assertMacro {
            """
            @ScopeState
            fileprivate struct TestView: View {
                @State fileprivate var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }
            }
            """
        } matches: {
            #"""
            fileprivate struct TestView: View {
                @State fileprivate var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }

                internal struct States: StatesProtocol {
                    var count = 0
                    internal static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] = [\.count: \.count]
                }
            }

            extension TestView: ActionSendable {
            }
            """#
        }
    }

    func testPrivateExpansion() {
        assertMacro {
            """
            @ScopeState
            private struct TestView: View {
                @State private var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }
            }
            """
        } matches: {
            #"""
            private struct TestView: View {
                @State private var count = 0
                let store: Store<TestReducer>

                init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
                    self.store = store
                }

                var body: some View {
                    EmptyView()
                }

                internal struct States: StatesProtocol {
                    var count = 0
                    internal static let keyPathMap: [PartialKeyPath<States>: PartialKeyPath<TestView>] = [\.count: \.count]
                }
            }

            extension TestView: ActionSendable {
            }
            """#
        }
    }
}
