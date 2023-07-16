import Foundation

public struct EffectTask<Reducer: ReducerProtocol>: Sendable {
    @usableFromInline
    enum EffectKind: @unchecked Sendable {
        case none
        case run(
            priority: TaskPriority?,
            operation: (_ send: Send<Reducer.Target>) async throws -> Void,
            catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)?
        )
        case serialAction([Reducer.Action])
        case concurrentAction([Reducer.Action])
        case serialReducerAction([Reducer.ReducerAction])
        case concurrentReducerAction([Reducer.ReducerAction])
        case serialCombineAction([CombineAction<Reducer>])
        case concurrentCombineAction([CombineAction<Reducer>])
    }

    let kind: EffectKind

    @usableFromInline
    init(effectKind: EffectKind) {
        self.kind = effectKind
    }
}

public extension EffectTask {
    @inlinable
    static var none: Self {
        .init(effectKind: .none)
    }

    @inlinable
    static func run(
        priority: TaskPriority? = nil,
        _ operation: @escaping (_ send: Send<Reducer.Target>) async throws -> Void,
        catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)? = nil
    ) -> Self {
        .init(effectKind: .run(priority: priority, operation: operation, catch: `catch`))
    }

    @inlinable
    static func concurrent(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .concurrentAction(actions))
    }

    @inlinable
    static func serial(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .serialAction(actions))
    }

    @inlinable
    static func concurrent(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .concurrentReducerAction(actions))
    }

    @inlinable
    static func serial(_ actions: Reducer.ReducerAction...) -> Self {
        .init(effectKind: .serialReducerAction(actions))
    }

    @inlinable
    static func concurrent(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .concurrentCombineAction(actions))
    }

    @inlinable
    static func serial(_ actions: CombineAction<Reducer>...) -> Self {
        .init(effectKind: .serialCombineAction(actions))
    }
}
