import Foundation

public struct CombineAction<Reducer: ReducerProtocol> {
    enum ActionKind {
        case viewAction(
            action: Reducer.Action
        )
        case reducerAction(
            action: Reducer.ReducerAction
        )
    }

    let kind: ActionKind

    init(kind: ActionKind) {
        self.kind = kind
    }
}

public extension CombineAction {
    static func action(
        _ action: Reducer.Action
    ) -> Self {
        .init(kind: .viewAction(action: action))
    }

    static func action(
        _ action: Reducer.ReducerAction
    ) -> Self {
        .init(kind: .reducerAction(action: action))
    }
}
