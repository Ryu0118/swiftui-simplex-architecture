import Dependencies

public struct _DependenciesOverrideModifier<Base: ReducerProtocol>: ReducerModifier {
    public let base: Base
    public let override: (inout DependencyValues) -> Void

    @usableFromInline
    init(base: Base, override: @escaping (inout DependencyValues) -> Void) {
        self.base = base
        self.override = override
    }

    @inlinable
    public func reduce(into state: StateContainer<Base.Target>, action: Base.Action) -> SideEffect<Base> {
        withDependencies(override) {
            base.reduce(into: state, action: action)
        }
    }

    @inlinable
    public func dependency<Value>(
        _ keyPath: WritableKeyPath<DependencyValues, Value>,
        value: Value
    ) -> Self {
        Self(base: base) { values in
            values[keyPath: keyPath] = value
            override(&values)
        }
    }
}

public extension ReducerProtocol {
    @inlinable
    func dependency<Value>(
        _ keyPath: WritableKeyPath<DependencyValues, Value>,
        value: Value
    ) -> _DependenciesOverrideModifier<Self> {
        .init(base: self) { values in
            values[keyPath: keyPath] = value
        }
    }
}
