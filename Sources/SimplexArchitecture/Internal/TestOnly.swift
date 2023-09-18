import Foundation
import XCTestDynamicOverlay

@propertyWrapper
struct TestOnly<T> {
    private var _value: T

    var wrappedValue: T {
        _read {
            if !_XCTIsTesting {
                runtimeWarning("\(Self.self) is accessible only during Unit tests")
            }
            yield _value
        }
        set {
            if _XCTIsTesting {
                _value = newValue
            }
        }
    }

    init(wrappedValue: T) {
        _value = wrappedValue
    }
}
