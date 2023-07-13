public protocol SimplexStoreBuilder<Reducer>: SimplexStoreView {
    var _store: Store<Self>? { get nonmutating set }
    func getStore() -> Store<Self>
}

public extension SimplexStoreBuilder {
    var store: Store<Self> {
        get {
            if let _store {
                return _store
            } else {
                let store = getStore()
                _store = store
                return store
            }
        }
        nonmutating set {
            _store = newValue
        }
    }
}
