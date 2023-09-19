import Foundation
import XCTestDynamicOverlay

extension Store {
    @usableFromInline
    @discardableResult
    func sendAction(
        _ action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        sendAction(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @usableFromInline
    func sendAction(
        _ action: consuming Reducer.ReducerAction,
        target: consuming Reducer.Target
    ) -> SendTask {
        sendAction(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @usableFromInline
    func sendAction(
        _ action: Reducer.Action,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        sendAction(.action(action), container: container)
    }

    @usableFromInline
    func sendAction(
        _ action: Reducer.ReducerAction,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        sendAction(.action(action), container: container)
    }

    @inline(__always)
    func sendAction(
        _ action: CombineAction<Reducer>,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        defer {
            switch action.kind {
            case .viewAction(let action):
                guard let pullbackAction else {
                    break
                }
                if let _ = Reducer.Action.self as? Pullbackable.Type {
                    pullbackAction(action)
                } else {
                    runtimeWarning("\(Reducer.Action.self) must be conformed to Pullbackable in order to pullback to parent reducer")
                }
            case .reducerAction(let action):
                guard let pullbackReducerAction else {
                    break
                }
                if let _ = Reducer.ReducerAction.self as? Pullbackable.Type {
                    pullbackReducerAction(action)
                } else {
                    runtimeWarning("\(Reducer.ReducerAction.self) must be conformed to Pullbackable in order to pullback to parent reducer")
                }
            }
        }

        let sideEffect: SideEffect<Reducer>
        // If Unit Testing is in progress and an action is sent from SideEffect
        if _XCTIsTesting, let effectContext = EffectContext.id {
            let before = container.copy()
            sideEffect = withLock {
                reducer.reduce(into: container, action: action)
            }
            sentFromEffectActions.append(
                ActionTransition(
                    previous: .init(state: before.states, reducerState: before._reducerState),
                    next: .init(state: container.states, reducerState: before._reducerState),
                    effect: sideEffect,
                    effectContext: effectContext,
                    for: action
                )
            )
        } else {
            sideEffect = withLock { reducer.reduce(into: container, action: action) }
        }

        if case .none = sideEffect.kind {
            return .never
        } else {
            let send = self.send ?? makeSend(for: container)

            return executeTasks(
                runEffect(sideEffect, send: send)
            )
        }
    }

    @usableFromInline
    @discardableResult
    func sendIfNeeded(_ action: Reducer.Action) -> SendTask {
        if let container {
            sendAction(action, container: container)
        } else {
            .never
        }
    }

    @usableFromInline
    @discardableResult
    func sendIfNeeded(_ action: Reducer.ReducerAction) -> SendTask {
        if let container {
            sendAction(action, container: container)
        } else {
            .never
        }
    }

    @inlinable
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }

    func makeSend(for container: StateContainer<Reducer.Target>) -> Send<Reducer> {
        Send(
            sendAction: { [weak self] action in
                self?.sendAction(action, container: container) ?? .never
            },
            sendReducerAction: { [weak self] reducerAction in
                self?.sendAction(reducerAction, container: container) ?? .never
            }
        )
    }
}
