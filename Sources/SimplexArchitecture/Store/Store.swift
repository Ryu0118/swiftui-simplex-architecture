import Foundation
import XCTestDynamicOverlay

/// `Store` is responsible for managing state and handling actions.
public final class Store<Reducer: ReducerProtocol> {
    // The container that holds the ViewState and ReducerState
    @usableFromInline
    var container: StateContainer<Reducer.Target>? {
        didSet {
            guard let container else { return }
            _send = makeSend(for: container)
        }
    }

    var _send: Send<Reducer>?
    // Buffer to store Actions recurrently invoked through SideEffect in a single Action sent from View
    @TestOnly var sentFromEffectActions: [ActionTransition<Reducer>] = []

    @usableFromInline var pullbackAction: ((Reducer.Action) -> Void)?
    @usableFromInline var pullbackReducerAction: ((Reducer.ReducerAction) -> Void)?

    let reduce: (StateContainer<Reducer.Target>, CombineAction<Reducer>) -> SideEffect<Reducer>
    var initialReducerState: (() -> Reducer.ReducerState)?

    /// Initialize  `Store` with the given reducer when the `ReducerState` is `Never`.
    public init(reducer: Reducer) where Reducer.ReducerState == Never {
        self.reduce = reducer.reduce
    }

    /// Initialize `Store` with the given `Reducer` and initial `ReducerState`.
    public init(
        reducer: Reducer,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        self.reduce = reducer.reduce
        self.initialReducerState = initialReducerState
    }

    public init<R: ReducerModifier<Reducer>>(
        reducer: R
    ) where Reducer.ReducerState == Never {
        self.reduce = reducer.reduce
    }

    /// Initialize `Store` with the given `Reducer` and initial `ReducerState`.
    public init<R: ReducerModifier<Reducer>>(
        reducer: R,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        self.reduce = reducer.reduce
        self.initialReducerState = initialReducerState
    }

    public func getContainer(
        for target: Reducer.Target,
        viewState: Reducer.Target.ViewState? = nil
    ) -> StateContainer<Reducer.Target> {
        if let container {
            container
        } else {
            StateContainer(target, viewState: viewState, reducerState: initialReducerState?())
        }
    }

    @inlinable
    @discardableResult
    public func setContainerIfNeeded(
        for target: Reducer.Target,
        viewState: Reducer.Target.ViewState? = nil
    ) -> StateContainer<Reducer.Target> {
        if let container {
            container.entity = target
            return container
        } else {
            let container = getContainer(for: target, viewState: viewState)
            self.container = container
            return container
        }
    }
}
