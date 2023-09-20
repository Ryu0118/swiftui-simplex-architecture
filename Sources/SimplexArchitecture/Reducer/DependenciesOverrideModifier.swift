import Dependencies

public struct _DependenciesOverrideModifier<Base: ReducerProtocol>: _ReducerModifier {
    public let base: Base
    public let override: (inout DependencyValues) -> Void

    public func reduce(into state: StateContainer<Base.Target>, action: Base.Action) -> SideEffect<Base> {
        withDependencies(override) {
            base.reduce(into: state, action: action)
        }
    }

    public func reduce(into state: StateContainer<Base.Target>, action: Base.ReducerAction) -> SideEffect<Base> {
        withDependencies(override) {
            base.reduce(into: state, action: action)
        }
    }

    public func dependency<Value>(
        _ keyPath: WritableKeyPath<DependencyValues, Value>,
        value: Value
    ) -> Self {
        Self(base: self.base) { values in
            values[keyPath: keyPath] = value
            override(&values)
        }
    }
}

public extension ReducerProtocol {
    func dependency<Value>(
        _ keyPath: WritableKeyPath<DependencyValues, Value>,
        value: Value
    ) -> _DependenciesOverrideModifier<Self> {
        .init(base: self) { values in
            values[keyPath: keyPath] = value
        }
    }
}
