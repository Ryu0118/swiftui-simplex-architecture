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
        sideEffect: SideEffect<Reducer>,
        effectContext: UUID,
        for action: CombineAction<Reducer>
    ) {
        self.previous = previous
        self.next = next
        effect = sideEffect
        self.effectContext = effectContext
        self.action = action
    }

    func toNextStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        toStateContainer(from: target, state: next)
    }

    func toPreviousStateContainer(from target: Reducer.Target) -> StateContainer<Reducer.Target> {
        toStateContainer(from: target, state: previous)
    }

    private func toStateContainer(from target: Reducer.Target, state _: Self.State) -> StateContainer<Reducer.Target> {
        .init(target, states: next.state, reducerState: next.reducerState)
    }
}
