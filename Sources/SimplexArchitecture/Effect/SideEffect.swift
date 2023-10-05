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
        case sendReducerAction(Reducer.ReducerAction)
        case serialAction([Reducer.Action])
        case concurrentAction([Reducer.Action])
        case serialReducerAction([Reducer.ReducerAction])
        case concurrentReducerAction([Reducer.ReducerAction])
        case serialCombineAction([CombineAction<Reducer>])
        case concurrentCombineAction([CombineAction<Reducer>])
        case runEffects([SideEffect<Reducer>])
    }

    // The kind of side effect.
    let kind: EffectKind

    @usableFromInline
    init(effectKind: EffectKind) {
        kind = effectKind
    }
}

public extension SideEffect {
    /// Creates a side effect of type `.none`.
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

    /// Creates a side effect that sends a specific reducer action.
    ///
    /// - Parameter action: The reducer action to send.
    ///
    /// - Returns: A side effect that represents sending the specified reducer action.
    @_disfavoredOverload
    @inlinable
    static func send(_ action: Reducer.ReducerAction) -> Self {
        .init(effectKind: .sendReducerAction(action))
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

    /// Creates a side effect that dispatches multiple reducer actions concurrently.
    ///
    /// - Parameter actions: An array of reducer actions to dispatch concurrently.
    ///
    /// - Returns: A side effect that represents dispatching the specified reducer actions concurrently.
    @_disfavoredOverload
    @inlinable
    static func concurrent(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .concurrentReducerAction(actions))
    }

    /// Creates a side effect that dispatches multiple reducer actions serially.
    ///
    /// - Parameter actions: An array of reducer actions to dispatch serially.
    ///
    /// - Returns: A side effect that represents dispatching the specified reducer actions serially.
    @_disfavoredOverload
    @inlinable
    static func serial(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .serialReducerAction(actions))
    }

    /// Creates a side effect that dispatches multiple `CombineAction` instances concurrently.
    ///
    /// - Parameter actions: An array of `CombineAction` instances to dispatch concurrently.
    ///
    /// - Returns: A side effect that represents dispatching the specified `CombineAction` instances concurrently.
    @_disfavoredOverload
    @inlinable
    static func concurrent(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .concurrentCombineAction(actions))
    }

    /// Creates a side effect that dispatches multiple `CombineAction` instances serially.
    ///
    /// - Parameter actions: An array of `CombineAction` instances to dispatch serially.
    ///
    /// - Returns: A side effect that represents dispatching the specified `CombineAction` instances serially.
    @_disfavoredOverload
    @inlinable
    static func serial(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .serialCombineAction(actions))
    }

    /// Creates a side effect that runs a list of other side effects.
    ///
    /// - Parameter effects: An array of `SideEffect` instances to run.
    ///
    /// - Returns: A side effect that represents running the specified side effects.
    @inlinable
    static func runEffects(_ effects: [SideEffect<Reducer>]) -> Self {
        .init(effectKind: .runEffects(effects))
    }
}
