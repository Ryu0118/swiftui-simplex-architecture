import Foundation

public final class Store<Target> where Target: SimplexStoreView {
    let reducer: Target.Reducer
    private var storeType: StoreType

    var isTargetIdentified: Bool {
        storeType.isTargetIdentified
    }

    public init(reducer: Target.Reducer, target: Target) where Target.Reducer.ReducerState == Never {
        let container = StateContainer(target)
        let send = Send(target: target, container: container)
        self.reducer = reducer
        self.storeType = .normal(send: send)
    }

    public init(reducer: Target.Reducer) where Target.Reducer.ReducerState == Never {
        self.reducer = reducer
        self.storeType = .normal()
    }

    public init(
        reducer: Target.Reducer,
        initialReducerState: @autoclosure @escaping () -> Target.Reducer.ReducerState
    ) {
        self.reducer = reducer
        self.storeType = .containReducerState(initialReducerState: initialReducerState)
    }
}

extension Store {
    @discardableResult
    func sendWhenContainReducerState(action: Target.Reducer.Action, target: Target) -> SendTask {
        switch storeType {
        case .normal:
            fatalError()
        case .containReducerState(let send, let initialReducerState):
            if let send {
                return send(action)
            } else {
                let send = Send(target: target, reducerState: initialReducerState())
                storeType = .containReducerState(send: send, initialReducerState: initialReducerState)
                return send(action)
            }
        }
    }

    func sendIfNeeded(action: Target.Reducer.Action) -> SendTask? {
        switch storeType {
        case .normal(let send), .containReducerState(let send, _):
            return send?(action)
        }
    }
}

extension Store where Target.Reducer.ReducerState == Never {
    @discardableResult
    func sendWhenNormalStore(action: Target.Reducer.Action, target: Target) -> SendTask {
        switch storeType {
        case .normal(let send):
            if let send {
                return send(action)
            } else {
                let send = Send(target: target)
                storeType = .normal(send: send)
                return send(action)
            }
        case .containReducerState:
            fatalError("Unreachable")
        }
    }
}

public extension Store where Target.Reducer.Action: ObservableAction {
    @_disfavoredOverload
    convenience init<each S>(
        reducer: Target.Reducer,
        target: Target,
        observableKeyPaths: repeat KeyPath<Target, each S>,
        observableProjectedKeyPaths: repeat KeyPath<Target, ObservableState<each S>>
    ) where Target.Reducer.ReducerState == Never {
        self.init(reducer: reducer, target: target)
    }

    @_disfavoredOverload
    convenience init<each S>(
        reducer: Target.Reducer,
        initialReducerState: Target.Reducer.ReducerState,
        observableKeyPaths: repeat KeyPath<Target, each S>,
        observableProjectedKeyPaths: repeat KeyPath<Target, ObservableState<each S>>
    ) {
        self.init(reducer: reducer, initialReducerState: initialReducerState)
    }
}

private extension Store {
    enum StoreType {
        case normal(
            send: Send<Target>? = nil
        )

        case containReducerState(
            send: Send<Target>? = nil,
            initialReducerState: () -> Target.Reducer.ReducerState
        )

        var isTargetIdentified: Bool {
            switch self {
            case .normal(let send), .containReducerState(let send, _):
                send == nil
            }
        }
    }
}
