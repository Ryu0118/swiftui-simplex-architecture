@testable import SimplexArchitecture
import XCTest

final class TaskResultTests: XCTestCase {
    func testCatching() {
        let result1 = TaskResult {
            throw CancellationError()
        }
        switch result1 {
        case .success:
            XCTFail()
        case .failure(let error):
            XCTAssertTrue(error is CancellationError)
        }

        let result2 = TaskResult {}
        switch result2 {
        case .success:
            break
        case .failure:
            XCTFail()
        }
    }
}
