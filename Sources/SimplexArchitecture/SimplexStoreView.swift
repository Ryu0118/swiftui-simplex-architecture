import SwiftUI

public protocol SimplexStoreView<Reducer>: View {
    associatedtype Reducer: ReducerProtocol<Self> where Reducer.State == StateContainer<Self>
    associatedtype States: StatesProtocol

    var store: Store<Self> { get nonmutating set }
}

public protocol StatesProtocol<Target> {
    associatedtype Target: SimplexStoreView
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}

public extension SimplexStoreView where Reducer.ReducerState == Never {
    func send(_ action: Reducer.Action) {
        if store.isSenderNil {
            store.sendWhenNormalStore(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action)
        }
    }
}

public extension SimplexStoreView {
    @_disfavoredOverload
    func send(_ action: Reducer.Action) {
        if store.isSenderNil {
            store.sendWhenContainReducerState(action: action, target: self)
        } else {
            store.sendIfNeeded(action: action)
        }
    }
}
