/// Macro for manually building a store in View.
///
/// Use this macro to manually generate a Reducer in Simplex Architecture. This is useful for Dependency Injection and using ReducerState
/// It is conformed to the `SimplexStoreBuilder` protocol by the `ScopedState` macro.
///
/// Example usage (Dependency Injection):
/// ```
/// @ScopedState(reducer: MyReducer.self)
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
/// @Reducer("MyView")
/// struct MyReducer {
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
/// @ScopedState(reducer: MyReducer.self)
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
/// @Reducer("MyView")
/// struct MyReducer {
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
@attached(member, names: named(States), named(Reducer))
@attached(extension)
public macro ScopedState<Reducer: ReducerProtocol>(reducer: Reducer.Type) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ScopedState")
