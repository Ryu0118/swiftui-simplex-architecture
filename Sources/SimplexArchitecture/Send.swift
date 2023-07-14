import Foundation

public final class Send<Target: SimplexStoreView>: @unchecked Sendable where Target.Reducer.State == StateContainer<Target> {
    private let target: Target
    private var container: StateContainer<Target>
    private var currentTask: Task<(), Never>?

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

    deinit {
        currentTask?.cancel()
    }
}

public extension Send {
    func callAsFunction(_ action: Target.Reducer.Action) async {
        await send(action)
    }

    func callAsFunction(_ action: Target.Reducer.Action) {
        send(action)
    }
}

private extension Send {
    func send(_ action: Target.Reducer.Action) {
        let effectTask = reduce(action)
        let tasks = runEffect(effectTask)

        // Root of Task Tree
        currentTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        await task.value
                    }
                }
            }
        }
    }

    func send(_ action: Target.Reducer.Action) async {
        let effectTask = reduce(action)
        let tasks = runEffect(effectTask)
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
        }
    }

    func runEffect(_ effectTask: EffectTask<Target.Reducer>) -> [Task<Void, Never>] {
        switch effectTask.kind {
        case .run(let priority, let operation, let `catch`):
            let task = Task.detached(priority: priority ?? .medium) {
                do {
                    try await operation(self)
                } catch {
                    if let `catch` {
                        await `catch`(error, self)
                    } else {
                        runtimeWarning(error.localizedDescription)
                    }
                }
            }
            return [task]

        case let .merge(actions):
            var tasks = [Task<Void, Never>]()
            for action in actions {
                let task = Task.detached {
                    await self.send(action)
                }
                tasks.append(task)
            }
            return tasks

        case let .concat(actions):
            let task = Task.detached {
                for action in actions {
                    await self.send(action)
                }
            }
            return [task]

        case .none:
            return []
        }
    }

    func reduce(_ action: Target.Reducer.Action) -> EffectTask<Target.Reducer> {
        target.store.reducer.reduce(into: &container, action: action)
    }
}
