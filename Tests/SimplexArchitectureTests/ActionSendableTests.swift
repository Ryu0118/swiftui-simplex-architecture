@testable import SimplexArchitecture
import SwiftUI
import XCTest

final class ActionSendableTests: XCTestCase {
    func testSend() {
        let testView = TestView()
        let sendTask1 = testView.send(.c1)
        XCTAssertNil(sendTask1.task)
        let sendTask2 = testView.send(.c2)
        XCTAssertNotNil(sendTask2.task)
    }

    func testAnimationSend() {
        let testView = TestView()
        let sendTask1 = testView.send(.c1, animation: .default)
        XCTAssertNil(sendTask1.task)
        let sendTask2 = testView.send(.c2, animation: .default)
        XCTAssertNotNil(sendTask2.task)
    }

    func testTransactionSend() {
        let testView = TestView()
        let sendTask1 = testView.send(.c1, transaction: .init(animation: .default))
        XCTAssertNil(sendTask1.task)
        let sendTask2 = testView.send(.c2, transaction: .init(animation: .default))
        XCTAssertNotNil(sendTask2.task)
    }
}

private struct TestReducer: ReducerProtocol {
    enum Action: Equatable {
        case c1
        case c2
    }

    func reduce(into _: StateContainer<TestView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .c1:
            return .none
        case .c2:
            return .send(.c1)
        }
    }
}

@ViewState
private struct TestView: View {
    let store: Store<TestReducer>

    init(store: Store<TestReducer> = Store(reducer: TestReducer())) {
        self.store = store
    }

    var body: some View {
        EmptyView()
    }
}
