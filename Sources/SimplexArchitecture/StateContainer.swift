import Foundation

@dynamicMemberLookup
public struct StateContainer<Target: SimplexStoreView>: @unchecked Sendable {
    var _reducerState: Target.Reducer.ReducerState?
    private var _entity: Target

    public var reducerState: Target.Reducer.ReducerState {
        _read { yield _reducerState! }
        _modify { yield &_reducerState! }
    }

    init(
        _ entity: consuming Target
    ) where Target.Reducer.ReducerState == Never {
        self._entity = entity
    }

    init(
        _ entity: consuming Target,
        reducerState: consuming Target.Reducer.ReducerState
    ) {
        self._entity = entity
        self.reducerState = reducerState
    }

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Target.States, U>) -> U {
        _read {
            if let viewKeyPath = Target.States.keyPathMap[keyPath] as? WritableKeyPath<Target, U>
            {
                yield _entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
        _modify {
            if let viewKeyPath = Target.States.keyPathMap[keyPath] as? WritableKeyPath<Target, U>
            {
                yield &_entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
    }

    @available(*, unavailable)
    public func onChange<U: Equatable>(_ keyPath: KeyPath<Target, ObservableState<U>>, perform: @escaping (U) -> Void) {
        _ = _entity.onChange(of: _entity[keyPath: keyPath]) { value in
            perform(value.wrappedValue)
        }
    }
}
