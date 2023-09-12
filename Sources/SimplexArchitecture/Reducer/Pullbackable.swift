import Foundation

/// If you want to pullback an Action to the parent Reducer, conform Pullbackable to the Action or ReducerAction of the child Reducer.
/// This protocol doesn’t have any required methods or properties
public protocol Pullbackable {}
