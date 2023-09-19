/// A type that can send actions back into the system when used from run(priority:operation:catch:fileID:line:).
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

    @_disfavoredOverload
    @discardableResult
    @inlinable
    func callAsFunction(_ action: Reducer.ReducerAction) -> SendTask {
        sendReducerAction(action)
    }

    /// Sends an action back into the system from an effect.
    @MainActor
    @inlinable
    public func callAsFunction(_ action: Reducer.Action) async {
        await sendAction(action).wait()
    }

    /// Sends an reducer action back into the system from an effect.
    @_disfavoredOverload
    @MainActor
    @inlinable
    public func callAsFunction(_ action: Reducer.ReducerAction) async {
        await sendReducerAction(action).wait()
    }
}
