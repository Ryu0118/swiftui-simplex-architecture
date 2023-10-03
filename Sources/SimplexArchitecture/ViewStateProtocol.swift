import Foundation

public protocol ViewStateProtocol<Target> {
    associatedtype Target: ActionSendable
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}
