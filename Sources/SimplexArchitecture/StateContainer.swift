import Foundation
import XCTestDynamicOverlay

// StateContainer is not thread-safe. Therefore, StateContainer must use NSLock or NSRecursiveLock for exclusions when changing values.
// In Send.swift, NSRecursiveLock is used for exclusions when executing the `reduce(into:action)`.
@dynamicMemberLookup
public final class StateContainer<Target: ActionSendable> {
    public var reducerState: Target.Reducer.ReducerState {
        _read { yield _reducerState! }
        _modify { yield &_reducerState! }
    }

    var _reducerState: Target.Reducer.ReducerState?
    var entity: Target
    @TestOnly var states: Target.States?

    init(
        _ entity: consuming Target,
        states: Target.States? = nil,
        reducerState: consuming Target.Reducer.ReducerState? = nil
    ) {
        self.entity = entity
        self.states = states
        self._reducerState = reducerState
    }

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Target.States, U>) -> U {
        _read {
            guard !_XCTIsTesting else {
                yield states![keyPath: keyPath]
                return
            }
            if let viewKeyPath = Target.States.keyPathMap[keyPath] as? WritableKeyPath<Target, U> {
                yield entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
        _modify {
            guard !_XCTIsTesting else {
                yield &states![keyPath: keyPath]
                return
            }
            if let viewKeyPath = Target.States.keyPathMap[keyPath] as? WritableKeyPath<Target, U> {
                yield &entity[keyPath: viewKeyPath]
            } else {
                fatalError()
            }
        }
    }

    func copy() -> Self {
        Self(entity, states: states, reducerState: _reducerState)
    }
}
