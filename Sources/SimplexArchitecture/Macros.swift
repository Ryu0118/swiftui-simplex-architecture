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
/// @Reducer
/// struct MyReducer {
///     enum ViewAction {
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
/// @Reducer
/// struct MyReducer {
///     enum ViewAction {
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

/// Macro for creating Action from ViewAction and ReducerAction, and conforming Reducer to ReducerProtocol
@attached(member, names: named(Action), named(ReducerAction))
@attached(extension, conformances: ReducerProtocol)
public macro Reducer() =
    #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ReducerMacro")
