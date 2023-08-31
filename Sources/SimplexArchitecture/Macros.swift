/// Macro for manually building a store in View.
///
/// Use this macro to manually generate a Reducer in Simplex Architecture. This is useful for Dependency Injection and using ReducerState
/// It is conformed to the `SimplexStoreBuilder` protocol by the `ScopeState` macro.
///
/// Example usage (Dependency Injection):
/// ```
/// @ScopeState
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
///     let authRepository: AuthRepository
///     let selfRepository: SelfRepository
///
///     func reduce(into state: inout StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .someAction:
///             return .none
///         }
///     }
/// }
/// ```
/// Example usage (ReducerState):
/// ```
/// @ScopeState
/// struct MyView: View {
///     let store: Store<MyReducer>
///
///     init(authRepository: AuthRepository, selfRepository: SelfRepository) {
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
///     func reduce(into state: inout StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .someAction:
///             state.reducerState.counter += 1
///             return .none
///         }
///     }
/// }
/// ```
/// - Parameters:
///   - reducer: The type of the reducer that handles state updates in the store. It should conform to the `ReducerProtocol`.
///
@attached(member, names: named(States))
@attached(extension, conformances: ActionSendable)
public macro ScopeState() = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ScopeState")
