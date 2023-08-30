import Foundation

public final class Send<Reducer: ReducerProtocol>: @unchecked Sendable {
    private let reducer: Reducer
    private var container: StateContainer<Reducer.Target>

    @usableFromInline
    let lock = NSRecursiveLock()

    init(
        reducer: consuming Reducer,
        target: consuming Reducer.Target
    ) where Reducer.ReducerState == Never {
        self.reducer = reducer
        self.container = StateContainer(target)
    }

    init(
        reducer: consuming Reducer,
        target: consuming Reducer.Target,
        reducerState: consuming Reducer.ReducerState
    ) {
        self.reducer = reducer
        self.container = StateContainer(target, reducerState: reducerState)
    }
}

// MARK: - Send Public Methods
public extension Send {
    @inlinable
    func callAsFunction(_ action: consuming Reducer.Action) async {
        await send(action).wait()
    }

    @inlinable
    func callAsFunction(_ action: consuming Reducer.ReducerAction) async {
        await send(action).wait()
    }
}

// MARK: - Send Internal Methods
extension Send {
    @inlinable
    @discardableResult
    func callAsFunction(_ action: consuming Reducer.Action) -> SendTask {
        send(action)
    }
}

// MARK: - Send Private Methods
extension Send {
    @usableFromInline
    func send(_ action: consuming Reducer.Action) -> SendTask {
        let sideEffect = withLock {
            reducer.reduce(into: &container, action: action)
        }
        if case .none = sideEffect.kind {
            return .init(task: nil)
        } else {
            let tasks = runEffect(sideEffect)
            return executeTasks(tasks)
        }
    }

    @usableFromInline
    func send(_ action: consuming Reducer.ReducerAction) -> SendTask {
        let sideEffect = withLock {
            reducer.reduce(into: &container, action: action)
        }
        if case .none = sideEffect.kind {
            return .init(task: nil)
        } else {
            let tasks = runEffect(sideEffect)
            return executeTasks(tasks)
        }
    }

    func executeTasks(_ tasks: [Task<Void, Never>]) -> SendTask {
        guard !tasks.isEmpty else {
            return .init(task: nil)
        }

        if tasks.count == 1,
           let task = tasks.first
        {
            return .init(task: task)
        }

        let task = Task.detached {
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        await withTaskCancellationHandler {
                            await task.value
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

    func runEffect(_ sideEffect: borrowing SideEffect<Reducer>) -> [Task<Void, Never>] {
        switch sideEffect.kind {
        case .run(let priority, let operation, let `catch`):
            let task = Task.detached(priority: priority ?? .medium) {
                do {
                    try await operation(self)
                } catch is CancellationError {
                    return
                } catch {
                    if let `catch` {
                        await `catch`(error, self)
                    } else {
                        runtimeWarning(error.localizedDescription)
                    }
                }
            }
            return [task]

        case let .sendAction(action):
            return [send(action)].compactMap(\.task)

        case let .sendReducerAction(action):
            return [send(action)].compactMap(\.task)

        case let .concurrentAction(actions):
            var tasks = [Task<Void, Never>]()
            for action in actions {
                let task = Task.detached {
                    await self.send(action).wait()
                }
                tasks.append(task)
            }
            return tasks

        case let .serialAction(actions):
            let task = Task.detached {
                for action in actions {
                    await self.send(action).wait()
                }
            }
            return [task]

        case let .concurrentReducerAction(actions):
            return actions
                .reduce(into: [SendTask]()) { tasks, action in
                    tasks.append(send(action))
                }
                .compactMap(\.task)

        case let .serialReducerAction(actions):
            let task = Task.detached {
                for action in actions {
                    await self.send(action).wait()
                }
            }
            return [task]

        case let .concurrentCombineAction(combineActions):
            return combineActions.compactMap { combineAction in
                switch combineAction.kind {
                case let .reducerAction(action):
                    send(action)
                case let .viewAction(action):
                    send(action)
                }
            }
            .compactMap(\.task)

        case let .serialCombineAction(combineActions):
            let task = Task.detached {
                for combineAction in combineActions {
                    switch combineAction.kind {
                    case let .reducerAction(action):
                        await self.send(action).wait()
                    case let .viewAction(action):
                        await self.send(action).wait()
                    }
                }
            }
            return [task]

        case .none:
            return []
        }
    }

    @inlinable
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
}
