import Foundation

/// If you want to pullback an Action to the parent Reducer, conform Pullbackable to the Action or ReducerAction of the child Reducer.
/// This protocol doesn’t have any required methods or properties
///
/// Here is a sample code.
/// ```
/// @ScopeState
/// struct ParentView: View {
///     let store: Store<ParentReducer> = Store(reducer: ParentReducer())
///
///     var body: some View {
///         ChildView()
///             .pullback(to: /ParentReducer.Action.child, parent: self)
///     }
/// }
///
/// struct ParentReducer: ReducerProtocol {
///     enum Action {
///         case child(ChildReducer.Action)
///     }
///
///     func reduce(into state: StateContainer<ParentView>, action: Action) -> SideEffect<ParentReducer> {
///         switch action {
///         case .child(.onButtonTapped):
///             // do something
///             return .none
///         }
///     }
/// }
///
/// @ScopeState
/// struct ChildView: View, ActionSendable {
///     let store: Store<ChildReducer> = Store(reducer: ChildReducer())
///
///     var body: some View {
///         Button("Child View") {
///             send(.onButtonTapped)
///         }
///     }
/// }
///
/// struct ChildReducer: ReducerProtocol {
///     enum Action: Pullbackable {
///         case onButtonTapped
///     }
///
///     func reduce(into state: StateContainer<ChildView>, action: Action) -> SideEffect<ChildReducer> {
///         switch action {
///         case .onButtonTapped:
///             return .none
///         }
///     }
/// }
/// ```
public protocol Pullbackable {}
