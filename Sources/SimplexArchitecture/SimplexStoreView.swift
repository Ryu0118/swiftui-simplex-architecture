import SwiftUI

public protocol SimplexStoreView<Reducer>: View {
    associatedtype Reducer: ReducerProtocol<Self> where Reducer.State == StateContainer<Self>
    associatedtype States: StatesProtocol

    var store: Store<Self> { get }
}

public protocol StatesProtocol<Target> {
    associatedtype Target: SimplexStoreView
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}

public extension SimplexStoreView where Reducer.ReducerState == Never {
    @discardableResult
    func send(_ action: consuming Reducer.Action) -> SendTask {
        if store.send == nil {
            store.sendIfReducerStateNever(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action)!
        }
    }
}

public extension SimplexStoreView {
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
