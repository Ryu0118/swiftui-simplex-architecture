import Foundation

/// A type representing a side effect, associated with a specific `Reducer`.
///
/// `SideEffect` is a versatile type that encapsulates various kinds of side effects. It can represent sending actions, running asynchronous operations, combining actions, and more.
public struct SideEffect<Reducer: ReducerProtocol>: Sendable {
    /// An enum that defines the various kinds of side effects.
    @usableFromInline
    enum EffectKind: @unchecked Sendable {
        case none
        case run(
            priority: TaskPriority?,
            operation: @Sendable (_ send: Send<Reducer>) async throws -> Void,
            catch: (@Sendable (_ error: any Error, _ send: Send<Reducer>) async -> Void)?
        )
        case sendAction(Reducer.Action)
        case serialAction([Reducer.Action])
        case concurrentAction([Reducer.Action])
        case serialEffect([SideEffect<Reducer>])
        case concurrentEffect([SideEffect<Reducer>])
        case cancel(id: AnyHashable)
        indirect case debounce(base: Self, id: AnyHashable, sleep: () async throws -> Void)
        indirect case cancellable(base: Self, id: AnyHashable, cancelInFlight: Bool)
    }

    // The kind of side effect.
    @usableFromInline
    let kind: EffectKind

    @usableFromInline
    init(effectKind: EffectKind) {
        kind = effectKind
    }
}

public extension SideEffect {
    /// Indicates no side effects
    ///
    /// - Returns: A side effect of type `.none`.
    @inlinable
    static var none: Self {
        .init(effectKind: .none)
    }

    /// Creates a side effect that runs an asynchronous operation.
    ///
    /// - Parameters:
    ///   - priority: The priority of the task.
    ///   - operation: The operation to perform.
    ///   - catch: A closure to handle errors that occur during the operation.
    ///
    /// - Returns: A side effect that represents running the specified asynchronous operation.
    @inlinable
    static func run(
        priority: TaskPriority? = nil,
        _ operation: @Sendable @escaping (_ send: Send<Reducer>) async throws -> Void,
        catch: (@Sendable (_ error: any Error, _ send: Send<Reducer>) async -> Void)? = nil
    ) -> Self {
        // If the .dependency modifier is used, the dependency must be conveyed to the escape context.
        withEscapedDependencies { continuation in
            .init(
                effectKind: .run(
                    priority: priority,
                    operation: { send in
                        try await continuation.yield {
                            try await operation(send)
                        }
                    },
                    catch: `catch`
                )
            )
        }
    }

    /// Creates a side effect that sends a specific action.
    ///
    /// - Parameter action: The action to send.
    ///
    /// - Returns: A side effect that represents sending the specified action.
    @inlinable
    static func send(_ action: Reducer.Action) -> Self {
        .init(effectKind: .sendAction(action))
    }

    /// Creates a side effect that dispatches multiple actions concurrently.
    ///
    /// - Parameter actions: An array of actions to dispatch concurrently.
    ///
    /// - Returns: A side effect that represents dispatching the specified actions concurrently.
    @inlinable
    static func concurrent(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .concurrentAction(actions))
    }

    /// Creates a side effect that dispatches multiple actions serially.
    ///
    /// - Parameter actions: An array of actions to dispatch serially.
    ///
    /// - Returns: A side effect that represents dispatching the specified actions serially.
    @inlinable
    static func serial(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .serialAction(actions))
    }

    /// Creates a side effect that run serially with an array of side effects.
    ///
    /// - Parameter effects: An array of `SideEffect` instances to run.
    ///
    /// - Returns: A side effect that represents running the specified side effects.
    @inlinable
    static func serial(_ effects: SideEffect<Reducer>...) -> Self {
        .init(effectKind: .serialEffect(effects))
    }

    /// Creates a side effect that run concurrently with an array of side effects.
    ///
    /// - Parameter effects: An array of `SideEffect` instances to run.
    ///
    /// - Returns: A side effect that represents running the specified side effects.
    @inlinable
    static func concurrent(_ effects: SideEffect<Reducer>...) -> Self {
        .init(effectKind: .concurrentEffect(effects))
    }
}

public extension SideEffect {
    /// Turns an side effect into one that can be debounced.
    ///
    /// debounce is an operator that plays only the last event in a sequence of SideEffects that have been issued for more than a certain time interval.
    /// To turn an effect into a debounce-able one you must provide an identifier, which is used to determine which in-flight effect should be canceled in order to start a new effect.
    ///
    /// - Parameters:
    ///   - id: The effect's identifier.
    ///   - duration: The duration you want to debounce for.
    ///   - clock: A clock conforming to the `Clock` protocol, used to measure the passing of time for the debounce duration.
    /// - Returns: A debounced version of the effect.
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @inlinable
    func debounce(
        id: some Hashable,
        for duration: Duration,
        clock: any Clock<Duration>
    ) -> Self {
        switch kind {
        case .none, .debounce:
            self
        default:
            .init(
                effectKind: .debounce(
                    base: kind,
                    id: AnyHashable(id),
                    sleep: {
                        try await clock.sleep(for: duration)
                    }
                )
            )
        }
    }

    /// Transforms the `SideEffect` into a cancellable version, allowing it to be cancelled if another `SideEffect`
    /// with the same identifier is triggered.
    ///
    /// - Parameters:
    ///   - id: A `Hashable` identifier for the `SideEffect`. This is used to track and cancel in-flight `SideEffect` instances.
    ///   - cancelInFlight: A Boolean value that determines whether in-flight `SideEffect` instances with the same identifier should be cancelled.
    ///     If true, any existing `SideEffect` with the same identifier will be cancelled before this one is executed. Defaults to false.
    ///
    /// - Returns: A cancellable version of the `SideEffect`. If the `SideEffect` is already of a kind that does not support
    ///   cancellation, or if it's already cancellable or debounced, the original `SideEffect` is returned unchanged.
    @inlinable
    func cancellable(
        id: some Hashable,
        cancelInFlight: Bool = false
    ) -> Self {
        switch kind {
        case .none, .cancellable, .debounce:
            self

        default:
            .init(
                effectKind: .cancellable(
                    base: kind,
                    id: AnyHashable(id),
                    cancelInFlight: cancelInFlight
                )
            )
        }
    }

    /// Creates a `SideEffect` that cancels any in-flight `SideEffect` instances with the given identifier.
    ///
    /// - Parameter id: The identifier of the `SideEffect` instances to cancel.
    ///
    /// - Returns: A `SideEffect` instance that will cancel in-flight `SideEffect` instances.
    @inlinable
    static func cancel(
        id: some Hashable
    ) -> Self {
        .init(effectKind: .cancel(id: id))
    }
}
