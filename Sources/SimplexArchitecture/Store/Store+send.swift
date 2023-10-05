import Foundation
import XCTestDynamicOverlay

extension Store {
    @usableFromInline
    @discardableResult
    func send(
        _ action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        send(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @usableFromInline
    func send(
        _ action: consuming Reducer.ReducerAction,
        target: consuming Reducer.Target
    ) -> SendTask {
        send(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @usableFromInline
    func send(
        _ action: Reducer.Action,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        send(.action(action), container: container)
    }

    @usableFromInline
    func send(
        _ action: Reducer.ReducerAction,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        send(.action(action), container: container)
    }

    @inline(__always)
    func send(
        _ action: CombineAction<Reducer>,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        defer {
            switch action.kind {
            case .viewAction(let action):
                guard let pullbackAction else { break }
                pullbackAction(action)
            case .reducerAction(let action):
                guard let pullbackReducerAction else { break }
                pullbackReducerAction(action)
            }
        }

        let sideEffect: SideEffect<Reducer>
        // If Unit Testing is in progress and an action is sent from SideEffect
        #if DEBUG
        @Dependency(\.isTesting) var isTesting
        if let effectContext = EffectContext.id, isTesting {
            let before = container.copy()
            sideEffect = reduce(container, action)
            sentFromEffectActions.append(
                ActionTransition(
                    previous: .init(state: before.viewState, reducerState: before._reducerState),
                    next: .init(state: container.viewState, reducerState: before._reducerState),
                    effect: sideEffect,
                    effectContext: effectContext,
                    for: action
                )
            )
        } else {
            sideEffect = reduce(container, action)
        }
        #else
        sideEffect = reduce(container, action)
        #endif

        if case .none = sideEffect.kind {
            return .never
        } else {
            let send = self._send ?? makeSend(for: container)

            return executeTasks(
                runEffect(sideEffect, send: send)
            )
        }
    }

    @usableFromInline
    @discardableResult
    func sendIfNeeded(_ action: Reducer.Action) -> SendTask {
        if let container {
            send(action, container: container)
        } else {
            .never
        }
    }

    @usableFromInline
    @discardableResult
    func sendIfNeeded(_ action: Reducer.ReducerAction) -> SendTask {
        if let container {
            send(action, container: container)
        } else {
            .never
        }
    }

    func makeSend(for container: StateContainer<Reducer.Target>) -> Send<Reducer> {
        Send(
            sendAction: { [weak self] action in
                self?.send(action, container: container) ?? .never
            },
            sendReducerAction: { [weak self] reducerAction in
                self?.send(reducerAction, container: container) ?? .never
            }
        )
    }
}
