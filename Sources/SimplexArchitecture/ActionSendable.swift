import SwiftUI

public protocol ActionSendable<Reducer> {
    associatedtype Reducer: ReducerProtocol<Self>
    associatedtype States: StatesProtocol

    var store: Store<Reducer> { get }
}

public protocol StatesProtocol<Target> {
    associatedtype Target: ActionSendable
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}

public extension ActionSendable where Reducer.ReducerState == Never {
    @discardableResult
    func send(_ action: consuming Reducer.Action) -> SendTask {
        threadCheck()
        return if store.send == nil {
            store.sendIfReducerStateNever(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action) ?? SendTask(task: nil)
        }
    }
}

public extension ActionSendable {
    /// Send an action to the store
    @discardableResult
    @_disfavoredOverload
    func send(_ action: consuming Reducer.Action) -> SendTask {
        threadCheck()
        return if store.send == nil {
            store.sendIfReducerStateExists(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action) ?? SendTask(task: nil)
        }
    }
}

private extension ActionSendable {
    @inline(__always)
    func threadCheck() {
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
