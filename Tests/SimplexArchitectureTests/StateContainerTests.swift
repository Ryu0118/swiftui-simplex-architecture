@testable import SimplexArchitecture
import SwiftUI
import XCTest

final class StateContainerTests: XCTestCase {
    func testInitialize() throws {
        let container = StateContainer(TestView(), states: .init())
        XCTAssertNotNil(container.entity)
        XCTAssertNotNil(container.states)
        XCTAssertNil(container._reducerState)
    }

    func testStateChange() throws {
        let container = StateContainer(TestView(), states: .init())
        XCTAssertEqual(container.count, 0)
        XCTAssertEqual(container.states?.count ?? .max, 0)
        container.count += 1
        XCTAssertEqual(container.count, 1)
        XCTAssertEqual(container.states?.count ?? .max, 1)
    }

    func testCopy() throws {
        let container = StateContainer(TestView(), states: .init(), reducerState: .init(count: 100))
        let copy = container.copy()
        XCTAssertEqual(String(customDumping: container.entity), String(customDumping: copy.entity))
        XCTAssertEqual(String(customDumping: container.states), String(customDumping: copy.states))
        XCTAssertEqual(container.reducerState, copy.reducerState)
    }
}

private struct TestReducer: ReducerProtocol {
    struct ReducerState: Equatable {
        var count = 0
    }

    enum Action: Equatable {
        case c1
        case c2
    }

    func reduce(into state: StateContainer<TestView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .c1:
            return .none
        case .c2:
            return .send(.c1)
        }
    }
}

@ScopeState
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
