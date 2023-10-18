import SwiftUI
@testable import SimplexArchitecture
import XCTest

@MainActor
final class SendTests: XCTestCase {
    func testNormalSend() {
        let isCalled = LockIsolated(false)
        let send: Send<EmptyReducer> = Send { _ in
            isCalled.setValue(true);
            return .never
        }
        send(.test)
        XCTAssertTrue(isCalled.value)
    }

    func testAnimationSend() {
        let isCalled = LockIsolated(false)
        let send: Send<EmptyReducer> = Send { _ in
            isCalled.setValue(true);
            return .never
        }
        send(.test, animation: .default)
        XCTAssertTrue(isCalled.value)
    }

    func testTransactionSend() {
        let isCalled = LockIsolated(false)
        let send: Send<EmptyReducer> = Send { _ in
            isCalled.setValue(true);
            return .never
        }
        send(.test, transaction: .init(animation: .default))
        XCTAssertTrue(isCalled.value)
    }
}

@Reducer
struct EmptyReducer {
    enum ViewAction {
        case test
    }

    func reduce(
        into state: StateContainer<EmptyViewState>,
        action: Action
    ) -> SideEffect<EmptyReducer> {
        .none
    }
}

@ViewState
final class EmptyViewState: ObservableObject {
    let store: Store<EmptyReducer> = .init(reducer: EmptyReducer())
}
