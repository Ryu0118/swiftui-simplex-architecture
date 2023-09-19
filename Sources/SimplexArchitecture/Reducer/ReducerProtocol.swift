/// A protocol that defines a reducer for a target type.
///
/// ```
/// struct MyReducer: ReducerProtocol {
///     enum Action {
///         case increment
///         case decrement
///     }
///
///     func reduce(into state: StateContainer<MyVIew>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .increment:
///             state.counter += 1
///             return .none
///         case .decrement:
///             state.counter -= 1
///             return .none
///         }
///     }
/// }
///
/// @ScopeState
/// struct MyView: View {
///     @State var counter = 0
///     let store = Store(reducer: MyReducer())
///
///     var body: some View {
///         VStack {
///             Text("\(counter)")
///             Button("+") {
///                 send(.increment)
///             }
///             Button("-") {
///                 send(.decrement)
///             }
///         }
///     }
/// }
///
/// ```
/// Also, `ReducerState` is useful to reduce unnecessary View updates. View is not updated when `ReducerState` changes. It can be used only with `Reducer`.
///
/// ```
/// struct MyReducer: ReducerProtocol {
///     enum Action {
///         case increment
///         case decrement
///     }
///
///     struct ReducerState {
///         var totalCalledCount = 0
///     }
///
///     func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         state.reducerState.totalCalledCount += 1
///         switch action {
///         case .increment:
///             state.counter += 1
///             return .none
///         case .decrement:
///             state.counter -= 1
///             return .none
///         }
///     }
/// }
///
/// @ScopeState
/// struct MyView: View {
///     @State var counter = 0
///
///     @State var store: Store<MyView>
///
///     init() {
///         store = Store(reducer: MyReducer(), initialReducerState: MyReducer.ReducerState())
///     }
///
///     var body: some View {
///         VStack {
///             Text("\(counter)")
///             Button("+") {
///                 send(.increment)
///             }
///             Button("-") {
///                 send(.decrement)
///             }
///         }
///     }
/// }
/// ```
///
public protocol ReducerProtocol<Target> {
    /// Target for the Reducer to change state, which must conform to ActionSendable and is automatically conformed to by the StoreBuilder or ScopeState macros
    associatedtype Target: ActionSendable<Self>
    /// State used by Reducer. Since the View is not update when the value of ReducerState is changed, it is used for the purpose of improving performance, etc.
    /// The default is Never.
    associatedtype ReducerState = Never
    /// A type that holds actions that change the state of the View.
    associatedtype Action
    /// Action used only within Reducer.
    ///
    /// Use when there are Actions that you do not want to expose to the View.
    associatedtype ReducerAction = Never
    /// Evolve the current state of ActionSendable to the next state.
    ///
    /// - Parameters:
    ///   - state: Current state of ActionSendable and ReducerState. ReducerState can be accessed from the `reducerState` property of State..
    ///   - action: An Action that can change the state of View and ReducerState.
    /// - Returns: An `SideEffect` representing the side effects generated by the reducer.
    func reduce(into state: StateContainer<Target>, action: Action) -> SideEffect<Self>
    /// Evolve the current state of ActionSendable to the next state.
    ///
    /// - Parameters:
    ///   - state: Current state of ActionSendable and ReducerState. ReducerState can be accessed from the `reducerState` property of State..
    ///   - action: A ReducerAction that can change the state of View and ReducerState.
    /// - Returns: An `SideEffect` representing the side effects generated by the reducer.
    func reduce(into state: StateContainer<Target>, action: ReducerAction) -> SideEffect<Self>
}

public extension ReducerProtocol where ReducerAction == Never {
    func reduce(
        into _: StateContainer<Target>,
        action _: ReducerAction
    ) -> SideEffect<Self> {}
}

extension ReducerProtocol {
    @inlinable
    func reduce(
        into state: StateContainer<Target>,
        action: CombineAction<Self>
    ) -> SideEffect<Self> {
        switch action.kind {
        case let .viewAction(action):
            reduce(into: state, action: action)

        case let .reducerAction(action):
            reduce(into: state, action: action)
        }
    }
}
