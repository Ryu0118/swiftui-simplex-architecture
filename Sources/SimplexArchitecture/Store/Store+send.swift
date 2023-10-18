import Foundation
import XCTestDynamicOverlay

extension Store {
    @_disfavoredOverload
    @discardableResult
    @inlinable
    func send(
        _ action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        send(action, container: setContainerIfNeeded(for: target))
    }

    @discardableResult
    @inlinable
    func send(
        _ action: consuming Reducer.ViewAction,
        target: consuming Reducer.Target
    ) -> SendTask {
        send(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @discardableResult
    @inlinable
    func send(
        _ action: consuming Reducer.ReducerAction,
        target: consuming Reducer.Target
    ) -> SendTask {
        send(
            action,
            container: setContainerIfNeeded(for: target)
        )
    }

    @inlinable
    func send(
        _ action: Reducer.ViewAction,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        send(Reducer.Action(viewAction: action), container: container)
    }

    @inlinable
    func send(
        _ action: Reducer.ReducerAction,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        send(Reducer.Action(reducerAction: action), container: container)
    }

    @_disfavoredOverload
    @usableFromInline
    func send(
        _ action: Reducer.Action,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        defer {
            if let pullbackAction {
                pullbackAction(action)
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
            let send = _send ?? makeSend(for: container)
            let tasks = runEffect(sideEffect, send: send)

            return reduce(tasks: tasks)
        }
    }

    // Combine multiple SendTasks into one Task
    func reduce(tasks: [SendTask]) -> SendTask {
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

        case let .runEffects(effects):
            return effects.reduce(into: [SendTask]()) { partialResult, effect in
                partialResult += runEffect(effect, send: send)
            }

        case .none:
            return []
        }
    }

    @inlinable
    func makeSend(for container: StateContainer<Reducer.Target>) -> Send<Reducer> {
        Send { [weak self] action in
            self?.send(action, container: container) ?? .never
        }
    }
}
