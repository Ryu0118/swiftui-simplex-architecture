@testable import SimplexArchitecture
import XCTest

final class TaskResultTests: XCTestCase {
    func testCatching() async {
        let result1 = await TaskResult {
            throw CancellationError()
        }
        switch result1 {
        case .success:
            XCTFail()
        case let .failure(error):
            XCTAssertTrue(error is CancellationError)
        }

        let result2 = await TaskResult {}
        switch result2 {
        case .success:
            break
        case .failure:
            XCTFail()
        }
    }
}
