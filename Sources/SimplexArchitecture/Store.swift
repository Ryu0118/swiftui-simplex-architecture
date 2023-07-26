import Foundation

public final class Store<Target> where Target: SimplexStoreView {
    @usableFromInline
    var send: Send<Target>?
    
    private let storeType: StoreType

    public init(
        reducer: consuming Target.Reducer,
        target: consuming Target
    ) where Target.Reducer.ReducerState == Never {
        self.send = Send(reducer: reducer, target: target)
        self.storeType = .normal
    }

    public init(
        reducer: @autoclosure @escaping () -> Target.Reducer,
        initialReducerState: @autoclosure @escaping () -> Target.Reducer.ReducerState
    ) {
        self.storeType = .containReducerState(reducer: reducer, initialReducerState: initialReducerState)
    }
}

extension Store {
    // ReducerState != Never
    @discardableResult
    func sendIfReducerStateExists(
        action: consuming Target.Reducer.Action,
        target: consuming Target
    ) -> SendTask {
        if let send {
            return send(action)
        } else {
            switch storeType {
            case .containReducerState(let reducer, let initialReducerState):
                let send = Send(reducer: reducer(), target: target, reducerState: initialReducerState())
                defer { self.send = send }
                return send(action)
            case .normal:
                fatalError("Unreachable")
            }
        }
    }

    // If no instance of the target View is passed to Store, the return value is nil.
    @inlinable
    func sendIfNeeded(action: consuming Target.Reducer.Action) -> SendTask? {
        send?(action)
    }
}

private extension Store {
    enum StoreType {
        case normal

        case containReducerState(
            reducer: () -> Target.Reducer,
            initialReducerState: () -> Target.Reducer.ReducerState
        )
    }
}
