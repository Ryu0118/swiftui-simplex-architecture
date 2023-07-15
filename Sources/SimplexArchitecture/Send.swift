import Foundation

public final class Send<Target: SimplexStoreView>: @unchecked Sendable where Target.Reducer.State == StateContainer<Target> {
    private let target: Target
    private var container: StateContainer<Target>
    private let lock = NSRecursiveLock()

    init(target: Target, container: StateContainer<Target>) {
        self.target = target
        self.container = container
    }

    init(target: Target) where Target.Reducer.ReducerState == Never {
        self.target = target
        self.container = StateContainer(target)
    }

    init(target: Target, reducerState: Target.Reducer.ReducerState) {
        self.target = target
        self.container = StateContainer(target, reducerState: reducerState)
    }
}

// MARK: - Send Public Methods
public extension Send {
    func callAsFunction(_ action: Target.Reducer.Action) async {
        await send(action).wait()
    }
}

// MARK: - Send Internal Methods
extension Send {
    @discardableResult
    func callAsFunction(_ action: Target.Reducer.Action) -> SendTask {
        send(action)
    }
}

// MARK: - Send Private Methods
private extension Send {
    func send(_ action: Target.Reducer.Action) -> SendTask {
        let effectTask = reduce(action)
        let tasks = runEffect(effectTask)

        guard !tasks.isEmpty else {
            return .init(task: nil)
        }

        let task = Task.detached {
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        guard !Task.isCancelled else {
                            return
                        }
                        await task.value
                    }
                }
                await group.waitForAll()
            }
        }

        return SendTask(task: task)
    }

    func runEffect(_ effectTask: EffectTask<Target.Reducer>) -> [Task<Void, Never>] {
        switch effectTask.kind {
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

        case let .concurrent(actions):
            var tasks = [Task<Void, Never>]()
            for action in actions {
                let task = Task.detached {
                    await self.send(action).wait()
                }
                tasks.append(task)
            }
            return tasks

        case let .serial(actions):
            let task = Task.detached {
                for action in actions {
                    await self.send(action).wait()
                }
            }
            return [task]

        case .none:
            return []
        }
    }

    func reduce(_ action: Target.Reducer.Action) -> EffectTask<Target.Reducer> {
        withLock {
            target.store.reducer.reduce(into: &container, action: action)
        }
    }

    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
}
