import Foundation

extension Store {
    @usableFromInline
    @discardableResult
    func sendAction(
        _ action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        let container = if let container {
            container
        } else {
            StateContainer(target, reducerState: initialReducerState?())
        }

        defer { self.container = container }

        return sendAction(action, container: container)
    }

    @usableFromInline
    func sendAction(
        _ action: consuming Reducer.ReducerAction,
        target: consuming Reducer.Target
    ) -> SendTask {
        let container = if let container {
            container
        } else {
            StateContainer(target, reducerState: initialReducerState?())
        }

        defer { self.container = container }

        return sendAction(action, container: container)
    }

    @usableFromInline
    func sendAction(
        _ action: Reducer.Action,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        defer {
            if let _ = Reducer.Action.self as? Pullbackable.Type, let pullbackAction {
                pullbackAction(action)
            }
        }

        threadCheck()

        let sideEffect = withLock {
            reducer.reduce(into: container, action: action)
        }
        if case .none = sideEffect.kind {
            return .never
        } else {
            let send =
                self.send
                    ?? Send(
                        sendAction: { [weak self] action in
                            self?.sendAction(action, container: container) ?? .never
                        },
                        sendReducerAction: { [weak self] reducerAction in
                            self?.sendAction(reducerAction, container: container) ?? .never
                        }
                    )

            return executeTasks(
                runEffect(sideEffect, send: send)
            )
        }
    }

    @usableFromInline
    func sendAction(
        _ action: Reducer.ReducerAction,
        container: StateContainer<Reducer.Target>
    ) -> SendTask {
        defer {
            if let _ = Reducer.ReducerAction.self as? Pullbackable.Type,
               let pullbackReducerAction
            {
                pullbackReducerAction(action)
            }
        }

        threadCheck()

        let sideEffect = withLock {
            reducer.reduce(into: container, action: action)
        }
        if case .none = sideEffect.kind {
            return .never
        } else {
            let send = self.send ?? Send(
                sendAction: { [weak self] action in
                    self?.sendAction(action, container: container) ?? .never
                },
                sendReducerAction: { [weak self] reducerAction in
                    self?.sendAction(reducerAction, container: container) ?? .never
                }
            )

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

    @inline(__always)
    func threadCheck() {
        #if DEBUG
            guard !Thread.isMainThread else {
                return
            }
            runtimeWarning(
                """
                "ActionSendable.send" was called on a non-main thread.

                The "Store" class is not thread-safe, and so all interactions with an instance of \
                "Store" must be done on the main thread.
                """
            )
        #endif
    }
}
