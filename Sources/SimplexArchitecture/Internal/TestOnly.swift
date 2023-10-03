import Foundation
import XCTestDynamicOverlay

@propertyWrapper
struct TestOnly<T> {
    private var _value: T

    @Dependency(\.isTesting) var isTesting

    var wrappedValue: T {
        _read {
            #if DEBUG
            if !isTesting {
                runtimeWarning("\(Self.self) is accessible only during Unit tests")
            }
            #endif
            yield _value
        }
        set {
            #if DEBUG
            if isTesting {
                _value = newValue
            }
            #endif
        }
    }

    init(wrappedValue: T) {
        _value = wrappedValue
    }
}
