import Foundation
import XCTestDynamicOverlay

/// `Store` is responsible for managing state and handling actions.
public final class Store<Reducer: ReducerProtocol> {
    // The container that holds the ViewState and ReducerState
    @usableFromInline
    var container: StateContainer<Reducer.Target>? {
        didSet {
            guard let container else { return }
            send = makeSend(for: container)
        }
    }

    var send: Send<Reducer>?
    // Buffer to store Actions recurrently invoked through SideEffect in a single Action sent from View
    @TestOnly var sentFromEffectActions: [ActionTransition<Reducer>] = []

    @usableFromInline let lock = NSRecursiveLock()
    @usableFromInline var pullbackAction: ((Reducer.Action) -> Void)?
    @usableFromInline var pullbackReducerAction: ((Reducer.ReducerAction) -> Void)?

    let reducer: Reducer
    var initialReducerState: (() -> Reducer.ReducerState)?

    /// Initialize  `Store` with the given reducer when the `ReducerState` is `Never`.
    public init(reducer: Reducer) where Reducer.ReducerState == Never {
        self.reducer = reducer
    }

    /// Initialize `Store` with the given `Reducer` and initial `ReducerState`.
    public init(
        reducer: Reducer,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        self.reducer = reducer
        self.initialReducerState = initialReducerState
    }

    public func getContainer(
        for target: Reducer.Target,
        states: Reducer.Target.States? = nil
    ) -> StateContainer<Reducer.Target> {
        if let container {
            container
        } else {
            StateContainer(target, states: states, reducerState: initialReducerState?())
        }
    }

    @inlinable
    @discardableResult
    public func setContainerIfNeeded(
        for target: Reducer.Target,
        states: Reducer.Target.States? = nil
    ) -> StateContainer<Reducer.Target> {
        if let container {
            return container
        } else {
            let container = getContainer(for: target, states: states)
            self.container = container
            return container
        }
    }
}

extension Store {
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
                    task: Task.withEffectContext {
                        send(action)
                    }
                ),
            ]

        case let .sendReducerAction(action):
            return [
                SendTask(
                    task: Task.withEffectContext {
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

        case .none:
            return []
        }
    }
}
