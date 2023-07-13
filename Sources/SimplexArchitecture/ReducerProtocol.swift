import Foundation

public protocol ReducerProtocol<Target> {
    associatedtype Target: SimplexStoreView
    associatedtype ReducerState
    associatedtype Action
    associatedtype State = StateContainer<Target>
    func reduce(into state: inout State, action: Action) -> EffectTask<Self>
}

public extension ReducerProtocol {
    typealias ReducerState = Never
}
