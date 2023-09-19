import Foundation

public struct CombineAction<Reducer: ReducerProtocol>: @unchecked Sendable {
    @usableFromInline
    enum ActionKind {
        case viewAction(
            action: Reducer.Action
        )
        case reducerAction(
            action: Reducer.ReducerAction
        )
    }

    @usableFromInline
    let kind: ActionKind

    @usableFromInline
    init(kind: ActionKind) {
        self.kind = kind
    }
}

public extension CombineAction {
    @inlinable
    static func action(
        _ action: Reducer.Action
    ) -> Self {
        .init(kind: .viewAction(action: action))
    }

    @inlinable
    static func action(
        _ action: Reducer.ReducerAction
    ) -> Self {
        .init(kind: .reducerAction(action: action))
    }
}

extension CombineAction: Equatable where CombineAction.ActionKind: Equatable {}
extension CombineAction.ActionKind: Equatable where Reducer.Action: Equatable, Reducer.ReducerAction: Equatable {}
extension CombineAction: Hashable where CombineAction.ActionKind: Hashable {}
extension CombineAction.ActionKind: Hashable where Reducer.Action: Hashable, Reducer.ReducerAction: Hashable {}
