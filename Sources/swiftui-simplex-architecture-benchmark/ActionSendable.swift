import SimplexArchitecture
import Benchmark
import Combine

let actionSendableSuite = BenchmarkSuite(name: "ActionSendable") {
    let testState = TestState()

    $0.benchmark("Mutate state") {
        testState.count += 1
    }

    $0.benchmark("Send action") {
        testState.send(.increment)
    }
}

@Reducer
private struct TestReducer {
    enum ViewAction: Equatable {
        case increment
    }

    func reduce(
        into state: StateContainer<TestState>,
        action: Action
    ) -> SideEffect<TestReducer> {
        switch action {
        case .increment:
            state.count += 1
            return .none
        }
    }
}

@ViewState
private final class TestState: ObservableObject {
    @Published var count = 0
    let store: Store<TestReducer> = .init(reducer: TestReducer())

    init(count: Int = 0) {
        self.count = count
    }
}
