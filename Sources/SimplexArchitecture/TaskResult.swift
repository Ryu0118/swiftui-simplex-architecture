public extension Result where Failure == Swift.Error {
    @inlinable
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}

public typealias TaskResult<Success> = Result<Success, Swift.Error>
