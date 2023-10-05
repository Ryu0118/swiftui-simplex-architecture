import Foundation
import XCTestDynamicOverlay

/// StateContainer is not thread-safe. StateContainer must be accessed from MainActor.
@dynamicMemberLookup
public final class StateContainer<Target: ActionSendable> {
    public var reducerState: Target.Reducer.ReducerState {
        _read { yield _reducerState! }
        _modify { yield &_reducerState! }
    }

    @Dependency(\.isTesting) private var isTesting
    @TestOnly var viewState: Target.ViewState?

    var _reducerState: Target.Reducer.ReducerState?
    var entity: Target

    init(
        _ entity: consuming Target,
        viewState: Target.ViewState? = nil,
        reducerState: consuming Target.Reducer.ReducerState? = nil
    ) {
        self.entity = entity
        self.viewState = viewState
        self._reducerState = reducerState
    }

    /// Returns Target value from Target.ViewState key path
    public subscript<U>(dynamicMember keyPath: WritableKeyPath<Target.ViewState, U>) -> U {
        _read {
            #if DEBUG
            guard !isTesting else {
                yield viewState![keyPath: keyPath]
                return
            }
            #endif
            if let viewKeyPath = Target.ViewState.keyPathMap[keyPath] as? WritableKeyPath<Target, U> {
                yield entity[keyPath: viewKeyPath]
            } else {
                fatalError(
                    """
                    Failed to get WritableKeyPath<Target, Value> from \(keyPath).
                    This operation does not normally fail
                    """
                )
            }
        }
        _modify {
            #if DEBUG
            guard !isTesting else {
                yield &viewState![keyPath: keyPath]
                return
            }
            #endif
            if let viewKeyPath = Target.ViewState.keyPathMap[keyPath] as? WritableKeyPath<Target, U> {
                yield &entity[keyPath: viewKeyPath]
            } else {
                fatalError(
                    """
                    Failed to get WritableKeyPath<Target, Value> from \(keyPath).
                    This operation does not normally fail
                    """
                )
            }
        }
    }

    func copy() -> Self {
        Self(entity, viewState: viewState, reducerState: _reducerState)
    }
}
