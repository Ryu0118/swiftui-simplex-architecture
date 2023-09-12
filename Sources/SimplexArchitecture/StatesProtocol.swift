import Foundation

public protocol StatesProtocol<Target> {
    associatedtype Target: ActionSendable
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}
