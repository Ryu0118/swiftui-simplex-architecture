public enum TaskResult<Success: Sendable>: Sendable {
    case success(Success)
    case failure(Error)
    
    public init(body: @Sendable () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
