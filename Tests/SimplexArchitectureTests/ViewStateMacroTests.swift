import MacroTesting
@testable import SimplexArchitecture
@testable import SimplexArchitectureMacrosPlugin
import SwiftUI
import XCTest

final class ViewStateMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: ["ViewState": ViewStateMacro.self]
        ) {
            super.invokeTest()
        }
    }

    func testDiagnostic() {
        assertMacro {
            """
            @ViewState
            public actor Test {
            }
            """
        } matches: {
            """
            @ViewState
            ┬─────────
            ├─ 🛑 'ViewState' macro can only be applied to struct or class
            ╰─ 🛑 'ViewState' macro can only be applied to struct or class
            public actor Test {
            }
            """
        }

        assertMacro {
            """
            @ViewState
            public protocol Test {
            }
            """
        } matches: {
            """
            @ViewState
            ┬─────────
            ├─ 🛑 'ViewState' macro can only be applied to struct or class
            ╰─ 🛑 'ViewState' macro can only be applied to struct or class
            public protocol Test {
            }
            """
        }

        assertMacro {
            """
            @ViewState
            public extension Test {
            }
            """
        } matches: {
            """
            @ViewState
            ┬─────────
            ├─ 🛑 'ViewState' macro can only be applied to struct or class
            ╰─ 🛑 'ViewState' macro can only be applied to struct or class
            public extension Test {
            }
            """
        }
    }

    func testPublicExpansion() {
        assertMacro {
            """
            @ViewState
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

                public struct ViewState: ViewStateProtocol {
                    var count = 0
                    public static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<TestView>] = [\.count: \.count]
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
            @ViewState
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

                 struct ViewState: ViewStateProtocol {
                    var count = 0
                     static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<TestView>] = [\.count: \.count]
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
            @ViewState
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

                internal struct ViewState: ViewStateProtocol {
                    var count = 0
                    internal static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<TestView>] = [\.count: \.count]
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
            @ViewState
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

                internal struct ViewState: ViewStateProtocol {
                    var count = 0
                    internal static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<TestView>] = [\.count: \.count]
                }
            }

            extension TestView: ActionSendable {
            }
            """#
        }
    }
}
