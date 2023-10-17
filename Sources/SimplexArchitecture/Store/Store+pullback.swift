import CasePaths
import Foundation

// MARK: - Pullback

extension Store {
    @inlinable
    func pullback<Parent: ActionSendable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, Reducer.Action>,
        parent: Parent
    ) {
        pullbackAction = { childAction in
            parent.store.send(casePath.embed(childAction), target: parent)
        }
    }

    @inlinable
    func pullback<Parent: ActionSendable, ID: Hashable>(
        to casePath: consuming CasePath<Parent.Reducer.Action, (id: ID, action: Reducer.Action)>,
        parent: Parent,
        id: consuming ID
    ) {
        pullbackAction = { childAction in
            parent.store.send(casePath.embed((id, childAction)), target: parent)
        }
    }
}
