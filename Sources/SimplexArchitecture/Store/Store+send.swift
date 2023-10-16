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

    func executeTasks(_ tasks: [SendTask]) -> SendTask {
        guard !tasks.isEmpty else {
            return .never
        }

        if tasks.count == 1,
           let task = tasks.first
        {
            return task
        }

        let task = Task.withEffectContext {
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        await withTaskCancellationHandler {
                            await task.wait()
                        } onCancel: {
                            task.cancel()
                        }
                    }
                }
                await group.waitForAll()
            }
        }

        return SendTask(task: task)
    }

    func runEffect(
        _ sideEffect: borrowing SideEffect<Reducer>,
        send: Send<Reducer>
    ) -> [SendTask] {
        switch sideEffect.kind {
        case let .run(priority, operation, `catch`):
            let task = Task.withEffectContext(priority: priority ?? .medium) {
                do {
                    try await operation(send)
                } catch is CancellationError {
                    return
                } catch {
                    if let `catch` {
                        await `catch`(error, send)
                    } else {
                        runtimeWarning(error.localizedDescription)
                    }
                }
            }
            return [SendTask(task: task)]

        case let .sendAction(action):
            return [
                SendTask(
                    task: Task.withEffectContext { @MainActor in
                        send(action)
                    }
                ),
            ]

        case let .sendReducerAction(action):
            return [
                SendTask(
                    task: Task.withEffectContext { @MainActor in
                        send(action)
                    }
                ),
            ]

        case let .concurrentAction(actions):
            return actions.reduce(into: [SendTask]()) { partialResult, action in
                partialResult.append(
                    SendTask(
                        task: Task.withEffectContext { @MainActor in
                            send(action)
                        }
                    )
                )
            }

        case let .serialAction(actions):
            let task = Task.withEffectContext {
                for action in actions {
                    await send(action)
                }
            }
            return [SendTask(task: task)]

        case let .concurrentReducerAction(actions):
            return actions.reduce(into: [SendTask]()) { tasks, action in
                tasks.append(
                    SendTask(
                        task: Task.withEffectContext { @MainActor in
                            send(action)
                        }
                    )
                )
            }

        case let .serialReducerAction(actions):
            let task = Task.withEffectContext {
                for action in actions {
                    await send(action)
                }
            }
            return [SendTask(task: task)]

        case let .concurrentCombineAction(combineActions):
            return combineActions.compactMap { combineAction in
                switch combineAction.kind {
                case let .reducerAction(action):
                    SendTask(
                        task: Task.withEffectContext { @MainActor in send(action) }
                    )
                case let .viewAction(action):
                    SendTask(
                        task: Task.withEffectContext { @MainActor in send(action) }
                    )
                }
            }

        case let .serialCombineAction(combineActions):
            let task = Task.withEffectContext {
                for combineAction in combineActions {
                    switch combineAction.kind {
                    case let .reducerAction(action):
                        await send(action)
                    case let .viewAction(action):
                        await send(action)
                    }
                }
            }
            return [SendTask(task: task)]

        case let .runEffects(effects):
            return effects.reduce(into: [SendTask]()) { partialResult, effect in
                partialResult += runEffect(effect, send: send)
            }

        case .none:
            return []
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
