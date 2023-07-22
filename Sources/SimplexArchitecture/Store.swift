import Foundation

public final class Store<Target> where Target: SimplexStoreView {
    let reducer: Target.Reducer

    @usableFromInline
    var send: Send<Target>?

    private var storeType: StoreType

    public init(
        reducer: consuming Target.Reducer,
        target: consuming Target
    ) where Target.Reducer.ReducerState == Never {
        self.send = Send(target: target)
        self.reducer = reducer
        self.storeType = .normal
    }

    public init(
        reducer: consuming Target.Reducer
    ) where Target.Reducer.ReducerState == Never {
        self.reducer = reducer
        self.storeType = .normal
    }

    public init(
        reducer: consuming Target.Reducer,
        initialReducerState: @autoclosure @escaping () -> Target.Reducer.ReducerState
    ) {
        self.reducer = reducer
        self.storeType = .containReducerState(initialReducerState: initialReducerState)
    }
}

extension Store {
    @discardableResult
    func sendIfReducerStateExists(
        action: consuming Target.Reducer.Action,
        target: consuming Target
    ) -> SendTask {
        if let send {
            return send(action)
        } else {
            switch storeType {
            case .containReducerState(let initialReducerState):
                let send = Send(target: target, reducerState: initialReducerState())
                defer { self.send = send }
                return send(action)
            case .normal:
                fatalError()
            }
        }
    }

    @inlinable
    func sendIfNeeded(action: consuming Target.Reducer.Action) -> SendTask? {
        send?(action)
    }
}

extension Store where Target.Reducer.ReducerState == Never {
    @discardableResult
    func sendIfNormalStore(action: consuming Target.Reducer.Action, target: Target) -> SendTask {
        if let send {
            return send(action)
        } else {
            let send = Send(target: target)
            return send(action)
        }
    }
}

private extension Store {
    enum StoreType {
        case normal

        case containReducerState(
            initialReducerState: () -> Target.Reducer.ReducerState
        )
    }
}
