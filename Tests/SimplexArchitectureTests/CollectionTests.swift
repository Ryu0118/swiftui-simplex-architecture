@testable import SimplexArchitecture
import XCTest

final class CollectionTests: XCTestCase {
    func testSafe() throws {
        let array = ["a", "b"]
        XCTAssertNotNil(array[safe: 1])
        XCTAssertNil(array[safe: 2])
    }
}
