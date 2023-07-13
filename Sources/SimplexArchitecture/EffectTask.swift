import Foundation

public struct EffectTask<Reducer: ReducerProtocol> {
    enum EffectKind {
        case none
        case run(
            priority: TaskPriority?,
            operation: (_ send: Send<Reducer.Target>) async throws -> Void,
            catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)?
        )
        case concat([Reducer.Action])
        case merge([Reducer.Action])
    }

    let kind: EffectKind

    init(effectKind: EffectKind) {
        self.kind = effectKind
    }
}

public extension EffectTask {
    static var none: Self {
        .init(effectKind: .none)
    }

    static func run(
        priority: TaskPriority? = nil,
        _ operation: @escaping (_ send: Send<Reducer.Target>) async throws -> Void,
        catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)? = nil
    ) -> Self {
        .init(effectKind: .run(priority: priority, operation: operation, catch: `catch`))
    }

    static func merge(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .merge(actions))
    }

    static func concat(_ actions: Reducer.Action...) -> Self {
        .init(effectKind: .concat(actions))
    }
}
