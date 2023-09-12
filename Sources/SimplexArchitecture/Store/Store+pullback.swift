import Foundation
import CasePaths

// MARK: - Pullback
extension Store {
    @inlinable
    public func pullback<Parent: ActionSendable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, Reducer.Action>,
        parent: Parent
    ) {
        pullbackAction = { childAction in
            parent.send(casePath.embed(childAction))
        }
    }

    @inlinable
    public func pullback<Parent: ActionSendable, ID: Hashable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, (id: ID, action: Reducer.Action)>,
        parent: Parent,
        id: consuming ID
    ) {
        pullbackAction = { childAction in
            parent.send(casePath.embed((id, childAction)))
        }
    }

    @inlinable
    public func pullback<Parent: ActionSendable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, Reducer.ReducerAction>,
        parent: Parent
    ) {
        pullbackReducerAction = { childAction in
            parent.send(casePath.embed(childAction))
        }
    }

    @inlinable
    public func pullback<Parent: ActionSendable, ID: Hashable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, (id: ID, action: Reducer.ReducerAction)>,
        parent: Parent,
        id: consuming ID
    ) {
        pullbackReducerAction = { childAction in
            parent.send(casePath.embed((id, childAction)))
        }
    }
}