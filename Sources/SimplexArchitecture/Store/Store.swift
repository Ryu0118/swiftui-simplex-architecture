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

    // Pullback Action to parent Store
    @usableFromInline
    var pullbackAction: ((Reducer.Action) -> Void)?
    // Buffer to store Actions recurrently invoked through SideEffect in a single Action sent from View
    @TestOnly
    var sentFromEffectActions: [ActionTransition<Reducer>] = []
    // If debounce or cancel is used in SideEffect, the task is stored here
    var cancellationStorage = CancellationStorage()

    var _send: Send<Reducer>?
    var initialReducerState: (() -> Reducer.ReducerState)?
    let reduce: (StateContainer<Reducer.Target>, Reducer.Action) -> SideEffect<Reducer>

    /// Initialize  `Store` with the given reducer when the `ReducerState` is `Never`.
    public init(reducer: Reducer) where Reducer.ReducerState == Never {
        reduce = reducer.reduce
    }

    /// Initialize `Store` with the given `Reducer` and initial `ReducerState`.
    public init(
        reducer: Reducer,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        reduce = reducer.reduce
        self.initialReducerState = initialReducerState
    }

    public init<R: ReducerModifier<Reducer>>(
        reducer: R
    ) where Reducer.ReducerState == Never {
        reduce = reducer.reduce
    }

    /// Initialize `Store` with the given `Reducer` and initial `ReducerState`.
    public init<R: ReducerModifier<Reducer>>(
        reducer: R,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        reduce = reducer.reduce
        self.initialReducerState = initialReducerState
    }

    deinit {
        cancellationStorage.cancelAll()
    }

    @discardableResult
    @usableFromInline
    func setContainerIfNeeded(
        for target: Reducer.Target,
        viewState: Reducer.Target.ViewState? = nil
    ) -> StateContainer<Reducer.Target> {
        if let container {
            container.target = target
            return container
        } else {
            let container = StateContainer(
                target,
                viewState: viewState,
                reducerState: initialReducerState?()
            )
            self.container = container
            return container
        }
    }
}
