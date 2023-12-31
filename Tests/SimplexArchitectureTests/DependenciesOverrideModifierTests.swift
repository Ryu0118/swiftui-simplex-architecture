@testable import SimplexArchitecture
import SwiftUI
import XCTest

@MainActor
final class DependenciesOverrideModifierTests: XCTestCase {
    func testModifier() async {
        let isCalled = LockIsolated(false)
        let base = BaseView(
            store: Store(
                reducer: _DependenciesOverrideModifier(base: BaseReducer()) {
                    $0.test = .init(asyncThrows: {
                        isCalled.setValue(true)
                    })
                }
            )
        )
        let container = base.store.setContainerIfNeeded(for: base, viewState: .init())
        await base.send(.test).wait()
        XCTAssertEqual(container.count, 1)
        XCTAssertTrue(isCalled.value)
    }
}

@Reducer
struct BaseReducer {
    enum ViewAction {
        case test
        case callback
    }

    @Dependency(\.test) var test

    func reduce(into state: StateContainer<BaseView>, action: Action) -> SideEffect<BaseReducer> {
        switch action {
        case .test:
            return .run { send in
                try await test.asyncThrows()
                await send(.callback)
            }
        case .callback:
            state.count += 1
            return .none
        }
    }
}

@ViewState
struct BaseView: View {
    @State var count: Int = 0
    let store: Store<BaseReducer>

    init(store: Store<BaseReducer> = .init(reducer: BaseReducer())) {
        self.store = store
    }

    var body: some View { EmptyView() }
}
