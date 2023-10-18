@testable import SimplexArchitecture
import SwiftUI
import XCTest

final class StateContainerTests: XCTestCase {
    func testInitialize() throws {
        let container = StateContainer(TestView(), viewState: .init())
        XCTAssertNotNil(container.target)
        XCTAssertNotNil(container.viewState)
        XCTAssertNil(container._reducerState)
    }

    func testStateChange() throws {
        let container = StateContainer(TestView(), viewState: .init())
        XCTAssertEqual(container.count, 0)
        XCTAssertEqual(container.viewState?.count ?? .max, 0)
        container.count += 1
        XCTAssertEqual(container.count, 1)
        XCTAssertEqual(container.viewState?.count ?? .max, 1)
    }

    func testCopy() throws {
        let container = StateContainer(TestView(), viewState: .init(), reducerState: .init(count: 100))
        let copy = container.copy()
        XCTAssertEqual(String(customDumping: container.target), String(customDumping: copy.target))
        XCTAssertEqual(String(customDumping: container.viewState), String(customDumping: copy.viewState))
        XCTAssertEqual(container.reducerState, copy.reducerState)
    }
}

@Reducer
private struct TestReducer {
    struct ReducerState: Equatable {
        var count = 0
    }

    enum ViewAction: Equatable {
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
    @State var count = 0
    let store: Store<TestReducer>

    init(store: Store<TestReducer> = Store(reducer: TestReducer(), initialReducerState: .init())) {
        self.store = store
    }

    var body: some View {
        EmptyView()
    }
}
