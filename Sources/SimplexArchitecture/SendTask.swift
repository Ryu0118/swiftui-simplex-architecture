import Foundation

/// The type returned from send(_:) that represents the lifecycle of the effect started from sending an action.
public struct SendTask: Sendable, Hashable {
    static let never = SendTask(task: nil)

    @usableFromInline
    let task: Task<Void, Never>?

    @inlinable
    init(task: consuming Task<Void, Never>?) {
        self.task = task
    }

    /// Waits for the task to complete asynchronously.
    @inlinable
    public func wait() async {
        await withTaskCancellationHandler {
            await task?.value
        } onCancel: {
            task?.cancel()
        }
    }

    /// Cancel the task.
    @inlinable
    public func cancel() {
        task?.cancel()
    }
}
