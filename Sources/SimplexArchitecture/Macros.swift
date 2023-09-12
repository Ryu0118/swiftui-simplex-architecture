/// Macro to create States structure by extracting properties to which property wrappers such as @State, @Binding @Published, etc. are applied.
///
/// It is conformed to the `ActionSendable` protocol by the `ScopeState` macro.
///
/// Here is a example code.
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
///     func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<MyReducer> {
///         switch action {
///         case .someAction:
///             state.reducerState.counter += 1
///             return .none
///         }
///     }
/// }
/// ```
@attached(member, names: named(States))
@attached(extension, conformances: ActionSendable)
public macro ScopeState() =
    #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ScopeState")
