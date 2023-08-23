public extension TaskResult where Failure == any Error {
    /// Creates a new task result by evaluating an async throwing closure.
    ///
    /// - Parameter body: An asynchronous throwing closure.
    @inlinable
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}

/// A typealias for a `Result` where the failure type is constrained to `Swift.Error`.
public typealias TaskResult<Success> = Result<Success, any Error>
