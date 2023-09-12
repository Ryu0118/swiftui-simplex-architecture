import Foundation

/// `Store` is responsible for managing state and handling actions.
public final class Store<Reducer: ReducerProtocol> {
    // The container that holds the ViewState and ReducerState
    var container: StateContainer<Reducer.Target>? {
        didSet {
            guard let container else { return }
            send = Send(
                sendAction: { [weak self] action in
                    self?.sendAction(action, container: container) ?? .never
                },
                sendReducerAction: { [weak self] reducerAction in
                    self?.sendAction(reducerAction, container: container) ?? .never
                }
            )
        }
    }

    var send: Send<Reducer>?

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

        let task = Task.detached {
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

    func runEffect(_ sideEffect: borrowing SideEffect<Reducer>, send: Send<Reducer>) -> [SendTask] {
        switch sideEffect.kind {
        case .run(let priority, let operation, let `catch`):
            let task = Task.detached(priority: priority ?? .medium) {
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
            return [send(action)]

        case let .sendReducerAction(action):
            return [send(action)]

        case let .concurrentAction(actions):
            return actions.reduce(into: [SendTask]()) { partialResult, action in
                partialResult.append(send(action))
            }

        case let .serialAction(actions):
            let task = Task.detached {
                for action in actions {
                    await send(action)
                }
            }
            return [SendTask(task: task)]

        case let .concurrentReducerAction(actions):
            return actions.reduce(into: [SendTask]()) { tasks, action in
                tasks.append(send(action))
            }

        case let .serialReducerAction(actions):
            let task = Task.detached {
                for action in actions {
                    await send(action)
                }
            }
            return [SendTask(task: task)]

        case let .concurrentCombineAction(combineActions):
            return combineActions.compactMap { combineAction in
                switch combineAction.kind {
                case let .reducerAction(action):
                    send(action)
                case let .viewAction(action):
                    send(action)
                }
            }

        case let .serialCombineAction(combineActions):
            let task = Task.detached {
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
