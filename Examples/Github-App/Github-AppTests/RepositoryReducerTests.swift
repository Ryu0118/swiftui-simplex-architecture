import Dependencies
@testable import Github_App
import SimplexArchitecture
import XCTest

@MainActor
final class RepositoryReducerTests: XCTestCase {
    func testOpenURLButtonTapped() async {
        let isCalled = LockIsolated(false)

        let store = RepositoryView(repository: .stub)
            .testStore(viewState: .init(repository: .stub)) {
                $0.openURL = .init { _ in isCalled.setValue(true); return true }
            }

        await store.send(.onOpenURLButtonTapped)

        XCTAssertTrue(isCalled.value)
    }
}
