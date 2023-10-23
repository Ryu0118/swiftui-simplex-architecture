import Foundation
import XCTestDynamicOverlay

/// Container that holds the reducer state and state for a given target conforming to `ActionSendable`.
///
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

    @usableFromInline
    var target: Target

    init(
        _ target: consuming Target,
        viewState: Target.ViewState? = nil,
        reducerState: consuming Target.Reducer.ReducerState? = nil
    ) {
        self.target = target
        self.viewState = viewState
        self._reducerState = reducerState
    }

    /// Returns Target value from Target.ViewState key path
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Target.ViewState, Value>) -> Value {
        _read {
            #if DEBUG
                guard !isTesting else {
                    yield viewState![keyPath: keyPath]
                    return
                }
            #endif
            if let viewKeyPath = Target.ViewState.keyPathMap[keyPath] as? WritableKeyPath<Target, Value> {
                yield target[keyPath: viewKeyPath]
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
            if let viewKeyPath = Target.ViewState.keyPathMap[keyPath] as? WritableKeyPath<Target, Value> {
                yield &target[keyPath: viewKeyPath]
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
        Self(target, viewState: viewState, reducerState: _reducerState)
    }
}
