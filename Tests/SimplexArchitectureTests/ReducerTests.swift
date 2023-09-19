@testable import SimplexArchitecture
import SwiftUI
import XCTest

@MainActor
final class ReducerTests: XCTestCase {
    func testReducer1() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.increment) {
            $0.count = 1
        }
        await testStore.send(.decrement) {
            $0.count = 0
        }
    }

    func testReducer2() async {
        let testStore = TestView().testStore(states: .init(count: 2))
        await testStore.send(.increment) {
            $0.count = 3
        }
        await testStore.send(.decrement) {
            $0.count = 2
        }
    }

    func testRun() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.run)
        await testStore.receive(.increment) {
            $0.count = 1
        }
        await testStore.receive(.decrement) {
            $0.count = 0
        }
    }

    func testSend() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.send)
        await testStore.receive(.increment) {
            $0.count = 1
        }
    }

    func testSerialAction() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.serial)
        await testStore.receive(.increment) {
            $0.count = 1
        }
        await testStore.receive(.decrement) {
            $0.count = 0
        }
    }

    func testConcurrentAction() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.concurrent)
        await testStore.receiveWithoutStateCheck(.increment, timeout: 0.5)
        await testStore.receiveWithoutStateCheck(.decrement, timeout: 0.5)
    }

    func testReducerState1() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.modifyReducerState1) {
            $0.reducerState.count = 1
            $0.reducerState.string = "hoge"
        }
    }

    func testReducerState2() async {
        let testStore = TestView(
            store: .init(
                reducer: TestReducer(),
                initialReducerState: .init(count: 2, string: "hoge")
            )
        ).testStore(states: .init())

        await testStore.send(.modifyReducerState2) {
            $0.reducerState.count = 3
            $0.reducerState.string = "hogehoge"
        }
    }

    func testReducerAction() async {
        let testStore = TestView().testStore(states: .init())
        await testStore.send(.invokeIncrement)
        await testStore.receive(.incrementFromReducerAction) {
            $0.count = 1
        }
        await testStore.send(.invokeDecrement)
        await testStore.receive(.decrementFromReducerAction) {
            $0.count = 0
        }
    }
}

private struct TestReducer: ReducerProtocol {
    struct ReducerState: Equatable {
        var count = 0
        var string = "string"
    }

    enum ReducerAction {
        case incrementFromReducerAction
        case decrementFromReducerAction
    }

    enum Action: Equatable {
        case increment
        case decrement
        case serial
        case concurrent
        case run
        case modifyReducerState1
        case modifyReducerState2
        case invokeIncrement
        case invokeDecrement
        case send
    }

    func reduce(into state: StateContainer<TestView>, action: ReducerAction) -> SideEffect<Self> {
        switch action {
        case .incrementFromReducerAction:
            state.count += 1
            return .none
        case .decrementFromReducerAction:
            state.count -= 1
            return .none
        }
    }

    func reduce(into state: StateContainer<TestView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .increment:
            state.count += 1
            return .none

        case .decrement:
            state.count -= 1
            return .none

        case .run:
            return .run { send in
                await send(.increment)
                await send(.decrement)
            }

        case .serial:
            return .serial(.increment, .decrement)

        case .concurrent:
            return .concurrent(.increment, .decrement)

        case .modifyReducerState1:
            state.reducerState.count = 1
            state.reducerState.string = "hoge"
            return .none

        case .modifyReducerState2:
            state.reducerState.count += 1
            state.reducerState.string += "hoge"
            return .none

        case .invokeIncrement:
            return .send(.incrementFromReducerAction)

        case .invokeDecrement:
            return .send(.decrementFromReducerAction)

        case .send:
            return .send(.increment)
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
