/// Macro to create ViewState struct by extracting properties to which property wrappers such as @State, @Binding @Published, etc. are applied.
///
/// It is conformed to the `ActionSendable` protocol by the `ViewState` macro.
///
/// Here is a example code.
/// ```
/// @ViewState
/// struct MyView: View {
///     let store: Store<MyReducer>
///
///     init(authRepository: AuthRepository, selfRepository: SelfRepository) {
///         store = Store(
///             reducer: MyReducer(
///                 authRepository: authRepository,
///                 selfRepository: selfRepository
///             )
///         )
///     }
///
///     var body: some View {
///         Text("MyView")
///     }
/// }
///
/// struct MyReducer: ReducerProtocol {
///     enum Action {
///         case someAction
///     }
///
///     @Dependency(\.authRepository) var authRepository
///     @Dependency(\.selfRepository) var selfRepository
///
///     func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .someAction:
///             return .none
///         }
///     }
/// }
/// ```
/// Here is a sample code if you want to use ReducerState.
/// ```
/// @ViewState
/// struct MyView: View {
///     let store: Store<MyReducer>
///
///     init() {
///         store = Store(reducer: MyReducer(), initialReducerState: .init(counter: 0))
///     }
///
///     var body: some View {
///         Text("MyView")
///             .onTapGesture {
///                 send(.someAction)
///             }
///     }
/// }
///
/// struct MyReducer: ReducerProtocol {
///     enum Action {
///         case someAction
///     }
///
///     struct ReducerState {
///         var counter: Int
///     }
///
///     func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .someAction:
///             state.reducerState.counter += 1
///             return .none
///         }
///     }
/// }
/// ```
@attached(member, names: named(ViewState))
@attached(extension, conformances: ActionSendable)
public macro ViewState() =
    #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ViewStateMacro")

@attached(member, names: named(Action), named(ReducerAction))
@attached(extension, conformances: ReducerProtocol)
public macro Reducer() =
    #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ReducerMacro")

import SwiftUI
@Reducer
struct MyReducer: ReducerProtocol {
    enum ViewAction {
        case increment
        case decrement
    }
    func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .increment:
            state.counter += 1
            return .none
        case .decrement:
            state.counter -= 1
            return .none
        }
    }
}

@ViewState
struct MyView: View {
    @State var counter = 0

    let store: Store<MyReducer> = Store(reducer: MyReducer())

    var body: some View {
        VStack {
            Text("\(counter)")
            Button("+") {
                send(.increment)
            }
            Button("-") {
                send(.decrement)
            }
        }
    }
}
