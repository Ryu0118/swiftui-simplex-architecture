/// Macro for building a store in View.
///
/// Use this macro to create a store with a specific reducer in View.
/// It is conformed to the `SimplexStoreView` protocol by the `StoreBuilder` macro.
///
/// Example usage:
/// ```
/// @StoreBuilder(reducer: MyReducer())
/// struct MyView: View {
///     @State var counter = 1
///     var body: some View {
///         Button("\(counter)") {
///             send(.countUp)
///         }
///     }
/// }
///
/// @Reducer("MyView")
/// struct MyReducer {
///     enum Action {
///         case countUp
///         case countDown
///     }
///
///     func reduce(into state: inout State, action: Action) -> EffectTask<MyReducer> {
///         switch action {
///         case .countUp:
///             state.counter += 1
///             return .none
///
///         case .countDown:
///             state.counter += 1
///             return .none
///         }
///     }
/// }
/// ```
///
/// - Parameters:
///   - reducer: An instance of a reducer conforming to the `ReducerProtocol`. It handles state updates in View.
///
@attached(member, names: named(States), named(makeStore), named(Reducer), named(_store))
@attached(conformance)
public macro StoreBuilder<Reducer: ReducerProtocol>(reducer: Reducer) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "StoreBuilder")

/// Macro for manually building a store in View.
///
/// Use this macro to manually generate a Reducer in Simplex Architecture. This is useful for Dependency Injection and using ReducerState
/// It is conformed to the `SimplexStoreBuilder` protocol by the `ManualStoreBuilder` macro.
///
/// Example usage (Dependency Injection):
/// ```
/// @ManualStoreBuilder(reducer: MyReducer.self)
/// struct MyView: View {
///     let store: Store<MyView>
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
///     func reduce(into state: inout State, action: Action) -> EffectTask<MyReducer> {
///         switch action {
///         case .someAction:
///             return .none
///         }
///     }
/// }
/// ```
/// Example usage (ReducerState):
/// ```
/// @ManualStoreBuilder(reducer: MyReducer.self)
/// struct MyView: View {
///     let store: Store<MyView>
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
///     func reduce(into state: inout State, action: Action) -> EffectTask<MyReducer> {
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
@attached(conformance)
public macro ManualStoreBuilder<Reducer: ReducerProtocol>(reducer: Reducer.Type) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ManualStoreBuilder")

/// Macro for creating a reducer.
///
/// Use this macro to define a reducer that handles state updates for a specific View.
/// It is conformed to the `ReducerProtocol` protocol by the `Reducer` macro.
///
/// Example usage:
/// ```
/// @Reducer("MyView")
/// struct MyReducer {
///     enum Action {
///         case someAction
///     }
///
///     func reduce(into state: inout State, action: Action) -> EffectTask<MyReducer> {
///         switch action {
///         case .someAction:
///             state.reducerState.counter += 1
///             return .none
///         }
///     }
/// }
/// ```
///
/// - Parameters:
///   - target: Name of the View that conforms to SimplexStoreView.
///
@attached(member, names: named(State), named(Target))
@attached(conformance)
public macro Reducer(_ target: String) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ReducerBuilderMacro")
