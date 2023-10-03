/// A marker type indicating a successful void result.
public struct VoidSuccess: Codable, Sendable, Hashable {
    public init() {}
}

/// An extension on `TaskResult` where the success type is `VoidSuccess`.
public extension TaskResult where Success == VoidSuccess {
    /// Creates a new task result by evaluating an async throwing closure.
    ///
    /// This initializer is used to handle asynchronous operations that produce a result of type `Void`.
    /// The provided async, throwing closure is executed in an asynchronous context. If the closure
    /// succeeds, the `TaskResult` is created with a success marker of type `VoidSuccess`. If the
    /// closure throws an error, the `TaskResult` is generated with the provided error as a failure.
    ///
    /// This initializer is often used within an async effect that's returned from a reducer.
    ///
    /// - Parameter body: An async, throwing closure.
    @_disfavoredOverload
    init(catching body: @Sendable () async throws -> Void) async {
        do {
            try await body()
            self = .success(VoidSuccess())
        } catch {
            self = .failure(error)
        }
    }
}
