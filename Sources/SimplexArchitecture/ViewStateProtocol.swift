import Foundation

/// A protocol that defines the ViewState of a specific Target.
/// Also, it must not use directly, since @ViewState generates a ViewState structure in Target that conforms to the ViewStateProtocol.
public protocol ViewStateProtocol<Target> {
    /// Copy the properties of the Target that conform to ActionSendable to ViewState.
    associatedtype Target: ActionSendable

    /// This is used by StateContainer to obtain the KeyPath of the Target property from the KeyPath of the ViewState property.
    /// This property is created by @ViewState.
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}
