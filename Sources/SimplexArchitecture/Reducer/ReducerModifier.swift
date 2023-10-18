import Dependencies
import Foundation

/// Protocols for modifying Reducer behavior
public protocol ReducerModifier<Base> {
    /// Reducer you want to change behavior
    associatedtype Base: ReducerProtocol

    /// Evolve the current state of ActionSendable to the next state.
    ///
    /// - Parameters:
    ///   - state: Current state of ActionSendable and ReducerState. ReducerState can be accessed from the `reducerState` property of State..
    ///   - action: An Action that can change the state of View and ReducerState.
    /// - Returns: An `SideEffect` representing the side effects generated by the reducer.
    func reduce(into state: StateContainer<Base.Target>, action: Base.Action) -> SideEffect<Base>
}
