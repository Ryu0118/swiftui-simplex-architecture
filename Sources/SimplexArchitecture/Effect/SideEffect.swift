import Foundation

public struct SideEffect<Reducer: ReducerProtocol>: Sendable {
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

    let kind: EffectKind

    @usableFromInline
    init(effectKind: EffectKind) {
        kind = effectKind
    }
}

public extension SideEffect {
    @inlinable
    static var none: Self {
        .init(effectKind: .none)
    }

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

    @inlinable
    static func send(_ action: Reducer.Action) -> Self {
        .init(effectKind: .sendAction(action))
    }

    @_disfavoredOverload
    @inlinable
    static func send(_ action: Reducer.ReducerAction) -> Self {
        .init(effectKind: .sendReducerAction(action))
    }

    @inlinable
    static func concurrent(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .concurrentAction(actions))
    }

    @inlinable
    static func serial(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .serialAction(actions))
    }

    @_disfavoredOverload
    @inlinable
    static func concurrent(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .concurrentReducerAction(actions))
    }

    @_disfavoredOverload
    @inlinable
    static func serial(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .serialReducerAction(actions))
    }

    @_disfavoredOverload
    @inlinable
    static func concurrent(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .concurrentCombineAction(actions))
    }

    @_disfavoredOverload
    @inlinable
    static func serial(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .serialCombineAction(actions))
    }

    @inlinable
    static func runEffects(_ effects: [SideEffect<Reducer>]) -> Self {
        .init(effectKind: .runEffects(effects))
    }
}
