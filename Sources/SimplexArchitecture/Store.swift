import Foundation

public final class Store<Reducer: ReducerProtocol> {
    @usableFromInline
    var send: Send<Reducer>?

    private let storeType: StoreType

    public init(
        reducer: consuming Reducer,
        target: consuming Reducer.Target
    ) where Reducer.ReducerState == Never {
        self.send = Send(reducer: reducer, target: target)
        self.storeType = .normal
    }

    public init(
        reducer: @autoclosure @escaping () -> Reducer
    ) where Reducer.ReducerState == Never {
        self.storeType = .lazy(reducer: reducer)
    }

    public init(
        reducer: @autoclosure @escaping () -> Reducer,
        initialReducerState: @autoclosure @escaping () -> Reducer.ReducerState
    ) {
        self.storeType = .containReducerState(reducer: reducer, initialReducerState: initialReducerState)
    }
}

extension Store {
    // ReducerState != Never
    @discardableResult
    func sendIfReducerStateExists(
        action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        if let send {
            return send(action)
        } else {
            switch storeType {
            case .containReducerState(let reducer, let initialReducerState):
                let send = Send(reducer: reducer(), target: target, reducerState: initialReducerState())
                defer { self.send = send }
                return send(action)
            case .normal, .lazy:
                return SendTask(task: nil)
            }
        }
    }

    // If no instance of the target View is passed to Store, the return value is nil.
    @inlinable
    func sendIfNeeded(action: consuming Reducer.Action) -> SendTask? {
        send?(action)
    }
}

extension Store where Reducer.ReducerState == Never {
    func sendIfReducerStateNever(
        action: consuming Reducer.Action,
        target: consuming Reducer.Target
    ) -> SendTask {
        if let send {
            return send(action)
        } else {
            switch storeType {
            case let .lazy(reducer):
                let send = Send(reducer: reducer(), target: target)
                defer { self.send = send }
                return send(action)
            default: return SendTask(task: nil)
            }
        }
    }
}

private extension Store {
    enum StoreType {
        case normal

        case lazy(reducer: () -> Reducer)

        case containReducerState(
            reducer: () -> Reducer,
            initialReducerState: () -> Reducer.ReducerState
        )
    }
}
