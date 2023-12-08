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
        } diagnostics: {
            """
            @ViewState
            public actor Test {
                         ┬───
                         ├─ 🛑 'ViewState' macro can only be applied to struct or class
                         ╰─ 🛑 'ViewState' macro can only be applied to struct or class
            }
            """
        }

        assertMacro {
            """
            @ViewState
            public protocol Test {
            }
            """
        } diagnostics: {
            """
            @ViewState
            public protocol Test {
                            ┬───
                            ├─ 🛑 'ViewState' macro can only be applied to struct or class
                            ╰─ 🛑 'ViewState' macro can only be applied to struct or class
            }
            """
        }

        assertMacro {
            """
            @ViewState
            public extension Test {
            }
            """
        } diagnostics: {
            """
            @ViewState
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
        } expansion: {
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
        } expansion: {
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
        } expansion: {
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
        } expansion: {
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
