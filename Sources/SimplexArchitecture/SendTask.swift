import Foundation

public struct SendTask: Sendable {
    private let task: Task<(), Never>?

    init(task: Task<(), Never>?) {
        self.task = task
    }

    public func wait() async {
        await withTaskCancellationHandler {
            await task?.value
        } onCancel: {
            task?.cancel()
        }
    }

    public func cancel() {
        task?.cancel()
    }
}
