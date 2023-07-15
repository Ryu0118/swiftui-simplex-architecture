import Foundation

public struct CombineAction<Reducer: ReducerProtocol> {
    enum ActionKind {
        case viewAction(
            operation: () async throws -> Reducer.Action,
            catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)?
        )
        case reducerAction(
            operation: () async throws -> Reducer.ReducerAction,
            catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)?
        )
    }

    let kind: ActionKind

    init(kind: ActionKind) {
        self.kind = kind
    }
}

public extension CombineAction {
    static func action(
        _ operation: @escaping () async throws -> Reducer.Action,
        catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)? = nil
    ) -> Self {
        .init(kind: .viewAction(operation: operation, catch: `catch`))
    }

    static func action(
        _ operation: @escaping () async throws -> Reducer.ReducerAction,
        catch: ((_ error: any Error, _ send: Send<Reducer.Target>) async -> Void)? = nil
    ) -> Self {
        .init(kind: .reducerAction(operation: operation, catch: `catch`))
    }
}
