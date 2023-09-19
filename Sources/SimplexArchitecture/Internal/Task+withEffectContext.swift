import Foundation

extension Task where Failure == any Error {
    // Granted when there is no EffectContext in the Task.
    @discardableResult
    static func withEffectContext(
        priority: TaskPriority? = nil,
        @_inheritActorContext @_implicitSelfCapture operation: @Sendable @escaping () async throws -> Success
    ) -> Self {
        if let _ = EffectContext.id {
            Self(priority: priority, operation: operation)
        } else {
            Self(priority: priority) {
                try await EffectContext.$id.withValue(UUID()) {
                    try await operation()
                }
            }
        }
    }
}

extension Task where Failure == Never {
    // Granted when there is no EffectContext in the Task.
    @discardableResult
    static func withEffectContext(
        priority: TaskPriority? = nil,
        @_inheritActorContext @_implicitSelfCapture operation: @Sendable @escaping () async -> Success
    ) -> Self {
        if let _ = EffectContext.id {
            Self(priority: priority, operation: operation)
        } else {
            Self(priority: priority) {
                await EffectContext.$id.withValue(UUID()) {
                    await operation()
                }
            }
        }
    }
}
