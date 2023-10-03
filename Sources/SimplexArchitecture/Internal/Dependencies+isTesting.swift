import Foundation

enum IsTestingKey: DependencyKey {
    static let liveValue: Bool = _XCTIsTesting
    static let testValue: Bool = _XCTIsTesting
}

extension DependencyValues {
    var isTesting: Bool {
        get { self[IsTestingKey.self] }
        set { self[IsTestingKey.self] = newValue }
    }
}
