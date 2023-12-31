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

    func testActionMustBeEnum() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public struct ViewAction {}
            }
            """
        } diagnostics: {
            """
            @Reducer
            public struct MyReducer {
                public struct ViewAction {}
                ┬──────────────────────────
                ╰─ 🛑 ViewAction must be enum
            }
            """
        }

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {}
                public struct ReducerAction {}
            }
            """
        } diagnostics: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {}
                public struct ReducerAction {}
                ┬─────────────────────────────
                ╰─ 🛑 ReducerAction must be enum
            }
            """
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
        } diagnostics: {
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

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable {
                    case decrement
                }
                public enum ReducerAction {
                    case increment
                }
            }
            """
        } diagnostics: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction: Equatable {
                    case decrement
                }
                public enum ReducerAction {
                ╰─ 🛑 The inheritance clause must match between ViewAction and ReducerAction
                    case increment
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
        } diagnostics: {
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
        } diagnostics: {
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

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                }
                public enum ReducerAction {
                    case increment(Int)
                }
            }
            """
        } diagnostics: {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case increment
                }
                public enum ReducerAction {
                    case increment(Int)
                         ┬────────
                         ╰─ 🛑 Cannot have duplicate cases in ViewAction and ReducerAction
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
        } diagnostics: {
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
        } diagnostics: {
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
        } diagnostics: {
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
        } diagnostics: {
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
        } expansion: {
            """
            package struct MyReducer {
                package enum ViewAction: Equatable {
                }
                package enum ReducerAction: Equatable {
                }

                @CasePathable package enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            internal struct MyReducer {
                internal enum ViewAction: Equatable {
                }
                internal enum ReducerAction: Equatable {
                }

                @CasePathable internal enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                @CasePathable  enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            fileprivate struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                @CasePathable internal enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            private struct MyReducer {
                enum ViewAction: Equatable {
                }
                enum ReducerAction: Equatable {
                }

                @CasePathable internal enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            public struct MyReducer {
                public enum ViewAction: Equatable {
                }
                public enum ReducerAction: Equatable {
                }

                @CasePathable public enum Action: Equatable , ActionProtocol {
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
        } expansion: {
            """
            public struct MyReducer {
                public enum ViewAction: Equatable, Hashable, Codable {
                }
                public enum ReducerAction: Equatable, Hashable, Codable {
                }

                @CasePathable public enum Action: Equatable, Hashable, Codable , ActionProtocol {
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
        } expansion: {
            """
            public struct MyReducer {
                public enum ViewAction {
                }
                public enum ReducerAction {
                }

                @CasePathable public enum Action: ActionProtocol {
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

    func testNestedAction() {
        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case alert(Alert)
                    public enum Alert {
                        case hoge(E1)
                        public enum E1 {
                            case fuga
                        }
                    }
                }
                public enum ReducerAction {
                    case request
                    case response(TaskResult<VoidSuccess>)
                }
            }
            """
        } expansion: {
            """
            public struct MyReducer {
                public enum ViewAction {
                    case alert(Alert)
                    public enum Alert {
                        case hoge(E1)
                        public enum E1 {
                            case fuga
                        }
                    }
                }
                public enum ReducerAction {
                    case request
                    case response(TaskResult<VoidSuccess>)
                }

                @CasePathable public enum Action: ActionProtocol {
                        case alert(Alert)
                        public typealias Alert = ViewAction.Alert

                        case request
                        case response(TaskResult<VoidSuccess>)
                        public init(viewAction: ViewAction) {
                            switch viewAction {
                            case .alert(let arg1):
                                self = .alert(arg1)
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
        } expansion: {
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

                @CasePathable public enum Action: ActionProtocol {
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

        assertMacro {
            """
            @Reducer
            public struct MyReducer {
                public enum ViewAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case decrement(arg1: String = "")
                }
            }
            """
        } expansion: {
            """
            public struct MyReducer {
                public enum ViewAction {
                    case decrement(arg1: String = "", arg2: Int? = nil)
                }
                public enum ReducerAction {
                    case decrement(arg1: String = "")
                }

                @CasePathable public enum Action: ActionProtocol {
                        case decrement(arg1: String = "", arg2: Int? = nil)

                        case decrement(arg1: String = "")
                        public init(viewAction: ViewAction) {
                            switch viewAction {
                            case .decrement(let arg1, let arg2):
                                self = .decrement(arg1: arg1, arg2: arg2)
                            }
                        }
                        public init(reducerAction: ReducerAction) {
                            switch reducerAction {
                            case .decrement(let arg1):
                                self = .decrement(arg1: arg1)
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
