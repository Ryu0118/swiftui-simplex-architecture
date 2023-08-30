public protocol SimplexStoreBuilder<Reducer>: SimplexStoreView {
    var _store: Store<Reducer>? { get nonmutating set }
    func makeStore() -> Store<Reducer>
}

public extension SimplexStoreBuilder {
    @inlinable
    var store: Store<Reducer> {
        get {
            if let _store {
                return _store
            } else {
                let store = makeStore()
                _store = store
                return store
            }
        }
        nonmutating set {
            _store = newValue
        }
    }

    @discardableResult
    @inlinable
    func send(_ action: consuming Reducer.Action) -> SendTask where Reducer.ReducerState == Never {
        store.sendIfNeeded(action: action)!
    }
}
