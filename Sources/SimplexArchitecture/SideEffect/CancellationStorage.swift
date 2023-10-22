import Foundation

final class CancellationStorage {
    private var cancellableTasks: [AnyHashable: Set<Task<Void, Never>>] = [:]
    private let lock = NSRecursiveLock()

    @inlinable
    func cancel(id: AnyHashable) {
        withLock {
            cancellableTasks[id]?.forEach { $0.cancel() }
            cancellableTasks[id] = nil
        }
    }

    @inlinable
    func append(id: AnyHashable, task: Task<Void, Never>) {
        withLock {
            cancellableTasks[id, default: []].insert(task)
        }
    }

    @inlinable
    func cancelAll() {
        withLock {
            cancellableTasks.values.forEach {
                $0.forEach { $0.cancel() }
            }
            cancellableTasks.removeAll()
        }
    }

    private func withLock<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
