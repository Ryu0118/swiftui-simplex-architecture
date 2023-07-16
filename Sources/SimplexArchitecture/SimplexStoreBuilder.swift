public protocol SimplexStoreBuilder<Reducer>: SimplexStoreView {
    var _store: Store<Self>? { get nonmutating set }
    func makeStore() -> Store<Self>
}

public extension SimplexStoreBuilder {
    @inlinable
    var store: Store<Self> {
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
}
