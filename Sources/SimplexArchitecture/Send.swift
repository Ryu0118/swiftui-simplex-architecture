import Foundation

public final class Send<Target: SimplexStoreView>: @unchecked Sendable where Target.Reducer.State == StateContainer<Target> {
    private let target: Target
    private var container: StateContainer<Target>
    private let lock = NSRecursiveLock()

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

    func callAsFunction(_ action: Target.Reducer.ReducerAction) async {
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
        let effectTask = reduceViewAction(action)
        let tasks = runEffect(effectTask)

        return executeTasks(tasks)
    }

    func send(_ action: Target.Reducer.ReducerAction) -> SendTask {
        let effectTask = reduceReducerAction(action)
        let tasks = runEffect(effectTask)

        return executeTasks(tasks)
    }

    func executeTasks(_ tasks: [Task<Void, Never>]) -> SendTask {
        guard !tasks.isEmpty else {
            return .init(task: nil)
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
            var tasks = [Task<Void, Never>]()
            for action in actions {
                let task = Task.detached {
                    await self.send(action).wait()
                }
                tasks.append(task)
            }
            return tasks

        case let .serialReducerAction(actions):
            let task = Task.detached {
                for action in actions {
                    await self.send(action).wait()
                }
            }
            return [task]

        case let .concurrentCombineAction(actions):
            return actions.flatMap { action in
                switch action.kind {
                case let .reducerAction(operation, `catch`):
                    return runEffect(
                        .run(
                            { try await $0(operation()) },
                            catch: `catch`
                        )
                    )
                case let .viewAction(operation, `catch`):
                    return runEffect(
                        .run(
                            { try await $0(operation()) },
                            catch: `catch`
                        )
                    )
                }
            }

        case let .serialCombineAction(actions):
            let task = Task.detached {
                for action in actions {
                    switch action.kind {
                    case let .reducerAction(operation, `catch`):
                        await self.runEffect(
                            .run(
                                { try await $0(operation()) },
                                catch: `catch`
                            )
                        )
                        .first?
                        .value
                    case let .viewAction(operation, `catch`):
                        await self.runEffect(
                            .run(
                                { try await $0(operation()) },
                                catch: `catch`
                            )
                        )
                        .first?
                        .value
                    }
                }
            }
            return [task]

        case .none:
            return []
        }
    }

    func reduceViewAction(_ action: Target.Reducer.Action) -> EffectTask<Target.Reducer> {
        withLock {
            target.store.reducer.reduce(into: &container, action: action)
        }
    }

    func reduceReducerAction(_ action: Target.Reducer.ReducerAction) -> EffectTask<Target.Reducer> {
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
