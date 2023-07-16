import Foundation

public struct SendTask: Sendable {
    @usableFromInline
    let task: Task<(), Never>?

    @inlinable
    init(task: consuming Task<(), Never>?) {
        self.task = task
    }

    @inlinable
    public func wait() async {
        await withTaskCancellationHandler {
            await task?.value
        } onCancel: {
            task?.cancel()
        }
    }

    @inlinable
    public func cancel() {
        task?.cancel()
    }
}
