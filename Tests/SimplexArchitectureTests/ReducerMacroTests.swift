import MacroTesting
@testable import SimplexArchitecture
@testable import SimplexArchitectureMacrosPlugin
import SwiftUI
import XCTest

final class ReducerMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: ["Reducer": ReducerMacro.self]
        ) {
            super.invokeTest()
        }
    }

    func testNoMatchInheritanceClause() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable {
                    case decrement
                }
                public enum ReducerAction: Equatable, Hashable {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
            }
            """
        } matches: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable {
                    case decrement
                }
                public enum ReducerAction: Equatable, Hashable {
                                         ┬────────────────────
                                         ╰─ 🛑 The inheritance clause must match between ViewAction and ReducerAction
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
            }
            """
        }
    }

    func testDuplicatedCases() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
            }
            """
        } matches: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                         ┬─────────────────────────────────────────────
                         ╰─ 🛑 Cannot have duplicate cases in ViewAction and ReducerAction
                }
            }
            """
        }

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                }
                public enum ReducerAction {
                    case increment
                    case decrement
                }
            }
            """
        } matches: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                }
                public enum ReducerAction {
                    case increment
                         ┬────────
                         ╰─ 🛑 Cannot have duplicate cases in ViewAction and ReducerAction
                    case decrement
                }
            }
            """
        }
    }

    func testNotStruct() {
        assertMacro {
            """
            @Reducer
            public class MyReducer {}
            """
        } matches: {
            """
            @Reducer
            ╰─ 🛑 @Reducer can only be applied to struct
            public class MyReducer {}
            """
        }
    }

    func testCannotFoundViewAction() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
            }
            """
        } matches: {
            """
            @Reducer
            ╰─ 🛑 ViewAction not found in MyReducer
            public struct MyReducer {
            }
            """
        }
    }

    func testTypealiasCannotBeUsed() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public typealias ViewAction = Hoge
            }
            """
        } matches: {
            """
            @Reducer
            public struct MyReducer {
                public typealias ViewAction = Hoge
                                 ┬─────────
                                 ╰─ 🛑 ViewAction cannot be defined with typealias
            }
            """
        }

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public typealias ReducerAction = Hoge
            }
            """
        } matches: {
            """
            @Reducer
            public struct MyReducer {
                public typealias ReducerAction = Hoge
                                 ┬────────────
                                 ╰─ 🛑 ReducerAction cannot be defined with typealias
            }
            """
        }
    }

    func testAccessModifier() {
        assertMacro {
            """
            @Reducer
            package struct MyReducer {
                package enum ViewAction: Equatable {
                }
                package enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            package struct MyReducer {
                package enum ViewAction: Equatable {
                }
                package enum ReducerAction: Equatable {
                }

                package enum Action: Equatable {
                    package init(viewAction: ViewAction) {
                        fatalError()
                    }
                    package init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }

        assertMacro {
            """
            @Reducer
            internal struct MyReducer {
                internal enum ViewAction: Equatable {
                }
                internal enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            internal struct MyReducer {
                internal enum ViewAction: Equatable {
                }
                internal enum ReducerAction: Equatable {
                }

                internal enum Action: Equatable {
                    internal init(viewAction: ViewAction) {
                        fatalError()
                    }
                    internal init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }

        assertMacro {
            """
            @Reducer
            struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                 enum Action: Equatable {
                 init(viewAction: ViewAction) {
                        fatalError()
                    }
                 init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }

        assertMacro {
            """
            @Reducer
            fileprivate struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            fileprivate struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                internal enum Action: Equatable {
                    internal init(viewAction: ViewAction) {
                        fatalError()
                    }
                    internal init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }

        assertMacro {
            """
            @Reducer
            private struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            private struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                internal enum Action: Equatable {
                    internal init(viewAction: ViewAction) {
                        fatalError()
                    }
                    internal init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }
    }

    func testInheritanceClause() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable {
                }
                public enum ReducerAction: Equatable {
                }
            }
            """
        } matches: {
            """
            public struct MyReducer {
                public enum ViewAction: Equatable {
                }
                public enum ReducerAction: Equatable {
                }

                public enum Action: Equatable {
                    public init(viewAction: ViewAction) {
                        fatalError()
                    }
                    public init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable, Hashable, Codable {
                }
                public enum ReducerAction: Equatable, Hashable, Codable {
                }
            }
            """
        } matches: {
            """
            public struct MyReducer {
                public enum ViewAction: Equatable, Hashable, Codable {
                }
                public enum ReducerAction: Equatable, Hashable, Codable {
                }

                public enum Action: Equatable, Hashable, Codable {
                    public init(viewAction: ViewAction) {
                        fatalError()
                    }
                    public init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }
    }

    func testNoCase() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                }
                public enum ReducerAction {
                }
            }
            """
        } matches: {
            """
            public struct MyReducer {
                public enum ViewAction {
                }
                public enum ReducerAction {
                }

                public enum Action {
                    public init(viewAction: ViewAction) {
                        fatalError()
                    }
                    public init(reducerAction: ReducerAction) {
                        fatalError()
                    }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }
    }

    func testMacroExpansion() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                    case decrement
                    case increment(arg1: String, arg2: Int)
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case request
                    case response(TaskResult<VoidSuccess>)
                }
            }
            """
        } matches: {
            """
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                    case decrement
                    case increment(arg1: String, arg2: Int)
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case request
                    case response(TaskResult<VoidSuccess>)
                }

                public enum Action {
                        case increment
                        case decrement
                        case increment(arg1: String, arg2: Int)
                        case decrement(arg1: String = "", arg2: Int? = nil)
                        case request
                        case response(TaskResult<VoidSuccess>)
                        public init(viewAction: ViewAction) {
                            switch viewAction {
                            case .increment:
                                self = .increment
                            case .decrement:
                                self = .decrement
                            case .increment(let arg1, let arg2):
                                self = .increment(arg1: arg1, arg2: arg2)
                            case .decrement(let arg1, let arg2):
                                self = .decrement(arg1: arg1, arg2: arg2)
                            }
                        }
                        public init(reducerAction: ReducerAction) {
                            switch reducerAction {
                            case .request:
                                self = .request
                            case .response(let arg1):
                                self = .response(arg1)
                            }
                        }
                }
            }

            extension MyReducer: ReducerProtocol {
            }
            """
        }
    }
}
