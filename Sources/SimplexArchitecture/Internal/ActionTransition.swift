import Foundation

/// ``ActionTransition`` represents a transition between viewState in a reducer. It captures the previous and next viewState, the associated side effect,effect context, and the action triggering the transition.
struct ActionTransition<Reducer: ReducerProtocol> {
    /// Represents a state. It includes the target state and the reducer state.
    struct State {
        let state: Reducer.Target.ViewState?
        let reducerState: Reducer.ReducerState?
    }

    /// The previous state.
    let previous: Self.State
    /// The next state.
    let next: Self.State
    /// The associated side effect.
    let effect: SideEffect<Reducer>
    /// The unique effect context that represents root effect.
    let effectContext: UUID
    /// The Action that cause a change of state
    let action: Reducer.Action

    /// - Parameters:
    ///   - previous: The previous state.
    ///   - next: The next state.
    ///   - effect: The unique effect context that represents parent effect.
    ///   - effectContext: The unique effect context that represents root effect.
    ///   - action: The action responsible for the transition.
    init(
        previous: Self.State,
        next: Self.State,
        effect: SideEffect<Reducer>,
        effectContext: UUID,
        for action: Reducer.Action
    ) {
        self.previous = previous
        self.next = next
        self.effect = effect
        self.effectContext = effectContext
        self.action = action
    }

    /// Converts the `ActionTransition` to a `StateContainer` representing the next state.
    ///
    /// - Parameter target: The target reducer.
    /// - Returns: A `StateContainer` representing the next state.
    func asNextStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        asStateContainer(from: target, state: next)
    }

    /// Converts the `ActionTransition` to a `StateContainer` representing the previous state.
    ///
    /// - Parameter target: The target reducer.
    /// - Returns: A `StateContainer` representing the previous state.
    func asPreviousStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        asStateContainer(from: target, state: previous)
    }

    private func asStateContainer(
        from target: Reducer.Target,
        state: Self.State
    ) -> StateContainer<Reducer.Target> {
        .init(
            target,
            viewState: state.state,
            reducerState: state.reducerState
        )
    }
}
