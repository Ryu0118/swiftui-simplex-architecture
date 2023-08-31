import SwiftUI

public protocol ActionSendable<Reducer>: View {
    associatedtype Reducer: ReducerProtocol<Self> where Reducer.Target == Self
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
        if store.send == nil {
            store.sendIfReducerStateNever(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action)!
        }
    }
}

public extension ActionSendable {
    /// Send an action to the store
    @discardableResult
    @_disfavoredOverload
    func send(_ action: consuming Reducer.Action) -> SendTask {
        if store.send == nil {
            store.sendIfReducerStateExists(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action)!
        }
    }
}
