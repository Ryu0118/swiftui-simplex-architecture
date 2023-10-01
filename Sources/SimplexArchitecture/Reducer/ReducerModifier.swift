import Foundation
import Dependencies

public protocol ReducerModifier<Base> {
    associatedtype Base: ReducerProtocol
    func reduce(into state: StateContainer<Base.Target>, action: Base.Action) -> SideEffect<Base>
    func reduce(into state: StateContainer<Base.Target>, action: Base.ReducerAction) -> SideEffect<Base>
}

public extension ReducerModifier {
    @inlinable
    func reduce(
        into state: StateContainer<Base.Target>,
        action: CombineAction<Base>
    ) -> SideEffect<Base> {
        switch action.kind {
        case let .viewAction(action):
            reduce(into: state, action: action)

        case let .reducerAction(action):
            reduce(into: state, action: action)
        }
    }
}
