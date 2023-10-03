import CustomDump

/// Result-like type that converts async throws to TaskResult objects
public enum TaskResult<Success: Sendable>: Sendable {
    case success(Success)
    case failure(any Error)

    @inlinable
    public init(catching body: () async throws -> Success) async {
        do {
            self = try .success(await body())
        } catch {
            self = .failure(error)
        }
    }

    @inlinable
    public func get() throws -> Success {
        switch self {
        case .success(let success):
            success
        case .failure(let error):
            throw error
        }
    }

    @inlinable
    public func map<T>(_ transform: (Success) -> T) -> TaskResult<T> {
        switch self {
        case let .success(value):
            return .success(transform(value))
        case let .failure(error):
            return .failure(error)
        }
    }
}

extension TaskResult: Equatable where Success: Equatable {
    public static func == (lhs: TaskResult<Success>, rhs: TaskResult<Success>) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsValue), .success(rhsValue)):
            lhsValue == rhsValue
        case let (.failure(lhsError), .failure(rhsError)):
            String(customDumping: lhsError) == String(customDumping: rhsError)
        default: false
        }
    }
}

extension TaskResult: Hashable where Success: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .success(let success):
            hasher.combine(success)
        case .failure(let error):
            if let error = error as? AnyHashable {
                hasher.combine(error)
            } else {
                hasher.combine("error")
            }
        }
    }
}
