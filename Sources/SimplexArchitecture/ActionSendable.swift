import CasePaths
import SwiftUI

/// A protocol for  send actions to a store.
public protocol ActionSendable<Reducer> {
    associatedtype Reducer: ReducerProtocol<Self>
    associatedtype ViewState: ViewStateProtocol

    /// The store to which actions will be sent.
    var store: Store<Reducer> { get }
}

public extension ActionSendable {
    /// Send an action to the store
    @discardableResult
    func send(_ action: consuming Reducer.ViewAction) -> SendTask {
        threadCheck()
        return store.send(action, target: self)
    }

    @discardableResult
    func send(_ action: consuming Reducer.ViewAction, animation: Animation?) -> SendTask {
        threadCheck()
        return withAnimation(animation) {
            store.send(action, target: self)
        }
    }

    /// Send an action to the store with transaction
    @discardableResult
    func send(_ action: consuming Reducer.ViewAction, transaction: Transaction) -> SendTask {
        threadCheck()
        return withTransaction(transaction) {
            store.send(action, target: self)
        }
    }

    @inline(__always)
    private func threadCheck() {
        #if DEBUG
            guard !Thread.isMainThread else {
                return
            }
            runtimeWarning(
                """
                "ActionSendable.send" was called on a non-main thread.

                The "Store" class is not thread-safe, and so all interactions with an instance of \
                "Store" must be done on the main thread.
                """
            )
        #endif
    }
}

public extension ActionSendable {
    /// Pullbacks the `Action` to the specified case path in the parent's reducer.
    ///
    /// - Parameters:
    ///   - casePath: The case path to which the action will be pulled back.
    ///   - parent: The parent `ActionSendable` to which the action will be sent.
    /// - Returns: Self
    @inlinable
    @discardableResult
    func pullback<Parent: ActionSendable>(
        to casePath: CasePath<Parent.Reducer.Action, Reducer.Action>,
        parent: Parent
    ) -> Self where Reducer.ReducerState == Never {
        store.pullback(to: casePath, parent: parent)
        return self
    }

    /// Pullbacks the `Action` to the specified case path with an associated identifier in the parent's reducer.
    /// This specifies an id to identify which View sent the Action in the ForEach.
    ///
    /// - Parameters:
    ///   - casePath: The case path with an associated identifier to which the action will be pulled back.
    ///   - parent: The parent `ActionSendable` to which the action will be sent.
    ///   - id: The identifier associated with the action.
    /// - Returns: Self.
    @inlinable
    @discardableResult
    func pullback<Parent: ActionSendable, ID: Hashable>(
        to casePath: CasePath<Parent.Reducer.Action, (id: ID, action: Reducer.Action)>,
        parent: Parent,
        id: ID
    ) -> Self where Reducer.ReducerState == Never {
        store.pullback(to: casePath, parent: parent, id: id)
        return self
    }
}
