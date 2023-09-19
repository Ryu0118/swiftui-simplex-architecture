import Foundation

struct ActionTransition<Reducer: ReducerProtocol> {
    struct State {
        let state: Reducer.Target.States?
        let reducerState: Reducer.ReducerState?
    }

    let previous: Self.State
    let next: Self.State
    let effect: SideEffect<Reducer>
    let effectContext: UUID
    let action: CombineAction<Reducer>

    init(
        previous: Self.State,
        next: Self.State,
        effect: SideEffect<Reducer>,
        effectContext: UUID,
        for action: CombineAction<Reducer>
    ) {
        self.previous = previous
        self.next = next
        self.effect = effect
        self.effectContext = effectContext
        self.action = action
    }

    func asNextStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        asStateContainer(from: target, state: next)
    }

    func asPreviousStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        asStateContainer(from: target, state: previous)
    }

    private func asStateContainer(from target: Reducer.Target, state: Self.State) -> StateContainer<Reducer.Target> {
        .init(target, states: state.state, reducerState: state.reducerState)
    }
}
