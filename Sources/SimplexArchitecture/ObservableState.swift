import SwiftUI

@available(*, unavailable)
@propertyWrapper
public struct ObservableState<T: Equatable> {
    let storage: State<T>

    public init(wrappedValue: T) {
        self.storage = State(initialValue: wrappedValue)
    }

    public var wrappedValue: T {
        get {
            storage.wrappedValue
        }
        nonmutating set {
            let oldValue = storage.wrappedValue
            storage.wrappedValue = newValue

            if oldValue != newValue {
                
            }
        }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    public var binding: Binding<T> {
        storage.projectedValue
    }
}

@available(*, unavailable)
extension ObservableState: Equatable {
    public static func == (lhs: ObservableState<T>, rhs: ObservableState<T>) -> Bool {
        lhs.storage.wrappedValue == rhs.storage.wrappedValue
    }
}

@available(*, unavailable)
extension ObservableState: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        storage.wrappedValue.hash(into: &hasher)
    }
}
