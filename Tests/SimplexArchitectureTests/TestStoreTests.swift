@testable import SimplexArchitecture
import SwiftUI
import XCTest

final class TestStoreTests: XCTestCase {
    func testSend() async throws {
        let store = TestView().testStore(viewState: .init())
        XCTAssertNil(store.runningContainer)
        XCTAssertTrue(store.runningTasks.isEmpty)
        let sendTask = await store.send(.increment) {
            $0.count = 1
        }
        XCTAssertEqual(store.runningTasks, [sendTask])
        XCTAssertNotNil(store.runningContainer)
    }

    func testReceive() async throws {
        let store = TestView().testStore(viewState: .init())
        XCTAssertTrue(store.runningTasks.isEmpty)

        let sendTask = await store.send(.receiveTest)
        XCTAssertTrue(store.testedActions.isEmpty)
        XCTAssertEqual(store.runningTasks, [sendTask])

        await store.receive(.increment) {
            $0.count = 1
        }
        XCTAssertEqual(store.testedActions.count, 1)
    }

    func testWithDependencies() async throws {
        let store = TestView().testStore(viewState: .init()) {
            $0.test = .init(asyncThrows: {})
        }

        await store.send(.run)
        await store.receive(.increment) {
            $0.count = 1
        }
    }

    func testNotEquatableActionWithFailure() async throws {
        let store = TestState().testStore(viewState: .init()) {
            $0.test = .init(asyncThrows: { throw CancellationError() })
        }

        await store.send(.test)
        await store.receive(\.receiveTest.failure)
    }

    func testNotEquatableActionWithSuccess() async throws {
        let store = TestState().testStore(viewState: .init()) {
            $0.test = .init(asyncThrows: {})
        }

        await store.send(.test)
        await store.receive(\.receiveTest.success) {
            $0.count = 1
        }
    }

    func testNotEquatableActionWithSuccessNoStateCheck() async throws {
        let store = TestState().testStore(viewState: .init()) {
            $0.test = .init(asyncThrows: {})
        }

        await store.send(.test)
        await store.receiveWithoutStateCheck(\.receiveTest.success)
    }
}

@Reducer
private struct TestReducer {
    enum ViewAction: Equatable {
        case increment
        case decrement
        case receiveTest
        case run
    }

    @Dependency(\.test) var test

    func reduce(into state: StateContainer<TestView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .increment:
            state.count += 1
            return .none

        case .decrement:
            state.count -= 1
            return .none

        case .receiveTest:
            return .send(.increment)

        case .run:
            return .run { send in
                try await test.asyncThrows()
                await send(.increment)
            }
        }
    }
}

@ViewState
private struct TestView: View {
    @State var count = 0
    let store: Store<TestReducer>

    init(store: Store<TestReducer> = Store(reducer: TestReducer())) {
        self.store = store
    }

    var body: some View {
        EmptyView()
    }
}

@Reducer
private struct NotEquatableReducer {
    public enum ViewAction {
        case test
        case receiveTest(Result<Void, any Error>)
    }

    @Dependency(\.test) var test

    public func reduce(into state: StateContainer<TestState>, action: Action) -> SideEffect<NotEquatableReducer> {
        switch action {
        case .test:
            return .run { send in
                await send(
                    .receiveTest(
                        Result { try await test.asyncThrows() }
                    )
                )
            }

        case .receiveTest(.success):
            state.count += 1
            return .none

        case .receiveTest(.failure):
            return .none
        }
    }
}

@ViewState
private final class TestState: ObservableObject {
    let store: Store<NotEquatableReducer> = .init(reducer: NotEquatableReducer())

    @Published var count = 0
}
