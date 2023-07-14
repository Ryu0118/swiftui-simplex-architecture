import Foundation

@dynamicMemberLookup
public struct StateContainer<Target: SimplexStoreView>: @unchecked Sendable {
    public var reducerState: ReducerStateContainer<Target>
    private var _entity: Target

    private let recursiveLock = NSRecursiveLock()

    init(_ entity: Target) where Target.Reducer.ReducerState == Never {
        self._entity = entity
        self.reducerState = ReducerStateContainer()
    }

    init(_ entity: Target, reducerState: Target.Reducer.ReducerState) {
        self._entity = entity
        self.reducerState = ReducerStateContainer(reducerState)
    }

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Target.States, U>) -> U {
        _read {
            defer { recursiveLock.unlock() }
            recursiveLock.lock()
            if let viewKeyPath = Target.States.keyPathMap[keyPath as PartialKeyPath<Target.States>] as? WritableKeyPath<Target, U>
            {
                yield _entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
        _modify {
            defer { recursiveLock.unlock() }
            recursiveLock.lock()
            if let viewKeyPath = Target.States.keyPathMap[keyPath as PartialKeyPath<Target.States>] as? WritableKeyPath<Target, U>
            {
                yield &_entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
    }

    public func onChange<U: Equatable>(_ keyPath: KeyPath<Target, ObservableState<U>>, perform: @escaping (U) -> Void) {
        _ = _entity.onChange(of: _entity[keyPath: keyPath]) { value in
            perform(value.wrappedValue)
        }
    }
}

@dynamicMemberLookup
public struct ReducerStateContainer<Target: SimplexStoreView>: @unchecked Sendable {
    private var _reducerStateEntity: Target.Reducer.ReducerState?

    private let recursiveLock = NSRecursiveLock()

    init(_ reducerStateEntity: Target.Reducer.ReducerState? = nil) {
        self._reducerStateEntity = reducerStateEntity
    }

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Target.Reducer.ReducerState, U>) -> U {
        _read {
            defer { recursiveLock.unlock() }
            recursiveLock.lock()
            yield _reducerStateEntity![keyPath: keyPath]
        }
        _modify {
            defer { recursiveLock.unlock() }
            recursiveLock.lock()
            yield &_reducerStateEntity![keyPath: keyPath]
        }
    }
}
