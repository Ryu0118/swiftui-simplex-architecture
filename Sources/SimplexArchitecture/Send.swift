/// A type that can send actions back into the system when used from run(priority:operation:catch:fileID:line:).
public struct Send<Reducer: ReducerProtocol>: Sendable {
    @usableFromInline
    let sendAction: @Sendable (Reducer.Action) -> SendTask

    @usableFromInline
    init(sendAction: @Sendable @escaping (Reducer.Action) -> SendTask) {
        self.sendAction = sendAction
    }

    /// Sends an action back into the system from an effect.
    @MainActor
    @discardableResult
    @inlinable
    public func callAsFunction(_ action: Reducer.Action) -> SendTask {
        sendAction(action)
    }
}
