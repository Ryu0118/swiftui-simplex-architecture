import XCTest
import Dependencies
import SimplexArchitecture
@testable import Github_App

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
