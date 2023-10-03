@testable import SimplexArchitecture
import XCTest

final class TestOnlyTests: XCTestCase {
    func testIsTesting() {
        var testOnly = withDependencies {
            $0.isTesting = true
        } operation: {
            TestOnly(wrappedValue: true)
        }
        testOnly.wrappedValue = false
        XCTAssertFalse(testOnly.wrappedValue)
    }

    func testIsNotTesting() {
        var testOnly = withDependencies {
            $0.isTesting = false
        } operation: {
            TestOnly(wrappedValue: true)
        }
        testOnly.wrappedValue = false
        XCTAssertTrue(testOnly.wrappedValue)
    }
}
