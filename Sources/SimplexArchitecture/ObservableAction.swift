import Foundation

public protocol ObservableAction<Target> {
    associatedtype Target: SimplexStoreView
    static func observe(_ keyPath: ObservedAction<Target>) -> Self
}

public struct ObservedAction<Target: SimplexStoreView>: @unchecked Sendable {
    public let keyPath: PartialKeyPath<Target>

    public static func ~= <Value>(
        keyPath: WritableKeyPath<Target, ObservableState<Value>>,
        observedAction: Self
    ) -> Bool {
        keyPath == observedAction.keyPath
    }
}
