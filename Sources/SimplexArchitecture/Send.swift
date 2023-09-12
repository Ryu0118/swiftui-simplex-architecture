public struct Send<Reducer: ReducerProtocol>: Sendable {
    @usableFromInline
    let sendAction: @Sendable (Reducer.Action) -> SendTask
    @usableFromInline
    let sendReducerAction: @Sendable (Reducer.ReducerAction) -> SendTask

    init(
        sendAction: @Sendable @escaping (Reducer.Action) -> SendTask,
        sendReducerAction: @Sendable @escaping (Reducer.ReducerAction) -> SendTask
    ) {
        self.sendAction = sendAction
        self.sendReducerAction = sendReducerAction
    }

    @discardableResult
    @inlinable
    func callAsFunction(_ action: Reducer.Action) -> SendTask {
        sendAction(action)
    }

    @discardableResult
    @inlinable
    func callAsFunction(_ action: Reducer.ReducerAction) -> SendTask {
        sendReducerAction(action)
    }

    @MainActor
    @inlinable
    public func callAsFunction(_ action: Reducer.Action) async {
        await sendAction(action).wait()
    }

    @MainActor
    @inlinable
    public func callAsFunction(_ action: Reducer.ReducerAction) async {
        await sendReducerAction(action).wait()
    }
}
