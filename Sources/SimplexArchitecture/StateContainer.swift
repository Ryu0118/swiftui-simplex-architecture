import Foundation

// StateContainer is not thread-safe. Therefore, StateContainer must use NSLock or NSRecursiveLock for exclusions when changing values.
// In Send.swift, NSRecursiveLock is used for exclusions when executing the `reduce(into:action)`.
@dynamicMemberLookup
public final class StateContainer<Target: ActionSendable> {
    public var reducerState: Target.Reducer.ReducerState {
        _read { yield _reducerState! }
        _modify { yield &_reducerState! }
    }

    private var _reducerState: Target.Reducer.ReducerState?
    private var _entity: Target

    init(_ entity: consuming Target) {
        self._entity = entity
    }

    init(
        _ entity: consuming Target,
        reducerState: consuming Target.Reducer.ReducerState?
    ) {
        self._entity = entity
        self._reducerState = reducerState
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
}
