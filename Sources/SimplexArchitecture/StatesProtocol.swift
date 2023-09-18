import Foundation

public protocol StatesProtocol<Target> {
    associatedtype Target: ActionSendable where Target.States == Self
    static var keyPathMap: [PartialKeyPath<Self>: PartialKeyPath<Target>] { get }
}
