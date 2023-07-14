import Foundation

public final class Send<Target: SimplexStoreView>: @unchecked Sendable where Target.Reducer.State == StateContainer<Target> {
    private let target: Target
    private var container: StateContainer<Target>

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

public extension Send {
    func callAsFunction(_ action: Target.Reducer.Action) async {
        await send(action)
    }
}

extension Send {
    func callAsFunction(_ action: Target.Reducer.Action) {
        Task {
            await send(action)
        }
    }
}

private extension Send {
    func send(_ action: Target.Reducer.Action) async {
        let effectTask = target.store.reducer.reduce(into: &container, action: action)

        switch effectTask.kind {
        case let .run(priority, operation, `catch`):
            await Task(priority: priority ?? .medium) {
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
            .value

        case let .merge(actions):
            for action in actions {
                Task {
                    await self(action)
                }
            }
            return

        case let .concat(actions):
            Task {
                for action in actions {
                    await self(action)
                }
            }
            return

        case .none:
            return
        }
    }
}
