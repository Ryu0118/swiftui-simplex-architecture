@testable import SimplexArchitecture
import SwiftUI
import XCTest
import CasePaths

final class StoreTests: XCTestCase {
    fileprivate var store: Store<TestReducer>!

    override func setUp() {
        super.setUp()
        store = Store(reducer: TestReducer())
    }

    func testSetContainerIfNeeded() throws {
        XCTAssertNil(store.container)
        XCTAssertNil(store.send)

        store.setContainerIfNeeded(for: TestView())

        XCTAssertNotNil(store.container)
        XCTAssertNotNil(store.send)
    }

    func testExecuteTasks() throws {
        let sendTask1 = store.executeTasks([])
        XCTAssertNil(sendTask1.task)

        let sendTask2 = store.executeTasks([.never])

        XCTAssertEqual(sendTask2, .never)
        XCTAssertNil(sendTask1.task)

        let sendTask3 = store.executeTasks([.never, .never])
        XCTAssertNotNil(sendTask3.task)
    }

    func testRunEffect() throws {
        store.setContainerIfNeeded(for: TestView())
        guard let send = store.send else {
            XCTFail("send is nil")
            return
        }

        let sendTasks1 = store.runEffect(.none, send: send)
        XCTAssertEqual(sendTasks1, [])

        let sendTasks2 = store.runEffect(.run { _ in }, send: send)
        XCTAssertEqual(sendTasks2.count, 1)
        XCTAssertNotNil(sendTasks2.first?.task)

        let sendTasks3 = store.runEffect(.send(.c1), send: send)
        XCTAssertEqual(sendTasks3.count, 1)
        XCTAssertNotNil(sendTasks3.first?.task)

        let sendTasks4 = store.runEffect(.serial(.c1, .c2), send: send)
        XCTAssertEqual(sendTasks4.count, 1)
        XCTAssertNotNil(sendTasks4.first?.task)

        let sendTasks5 = store.runEffect(.concurrent(.c1, .c2), send: send)
        XCTAssertEqual(sendTasks5.count, 2)
        for task in sendTasks5.map(\.task) {
            XCTAssertNotNil(task)
        }

        let sendTasks6 = store.runEffect(.send(.c3), send: send)
        XCTAssertEqual(sendTasks6.count, 1)
        XCTAssertNotNil(sendTasks6.first?.task)

        let sendTasks7 = store.runEffect(.serial(.c3, .c4), send: send)
        XCTAssertEqual(sendTasks7.count, 1)
        XCTAssertNotNil(sendTasks5.first?.task)

        let sendTasks8 = store.runEffect(.concurrent(.c3, .c4), send: send)
        XCTAssertEqual(sendTasks8.count, 2)
        for task in sendTasks8.map(\.task) {
            XCTAssertNotNil(task)
        }
    }

    func testSendAction() async throws {
        let container = store.setContainerIfNeeded(for: TestView())
        let sendTask1 = store.sendAction(.action(.c1), container: container)
        XCTAssertEqual(store.sentFromEffectActions.count, 0)
        XCTAssertNil(sendTask1.task)

        let sendTask2 = store.sendAction(.action(.c2), container: container)
        XCTAssertNotNil(sendTask2.task)
    }

    func testSendIfNeeded() throws {
        let sendTask1 = store.sendIfNeeded(.c1)
        XCTAssertEqual(sendTask1, .never)

        store.setContainerIfNeeded(for: TestView())
        let sendTask2 = store.sendIfNeeded(.c2)

        XCTAssertNotNil(sendTask2.task)
    }

    func testPullbackAction() throws {
        let parent = ParentView()
        parent.store.setContainerIfNeeded(for: parent, viewState: .init())
        store.setContainerIfNeeded(for: TestView())
        XCTAssertNil(store.pullbackAction)
        store.pullback(to: /ParentReducer.Action.child, parent: parent)
        store.sendIfNeeded(.c1)
        XCTAssertNotNil(store.pullbackAction)
        XCTAssertEqual(parent.store.container?.count, 1)
    }

    func testPullbackReducerAction() throws {
        let parent = ParentView()
        parent.store.setContainerIfNeeded(for: parent, viewState: .init())
        store.setContainerIfNeeded(for: TestView())
        XCTAssertNil(store.pullbackReducerAction)
        store.pullback(to: /ParentReducer.Action.childReducerAction, parent: parent)
        store.sendIfNeeded(.c4)
        XCTAssertNotNil(store.pullbackReducerAction)
        XCTAssertEqual(parent.store.container?.count, 1)
    }

    func testPullbackActionForId() throws {
        let parent = ParentView()
        parent.store.setContainerIfNeeded(for: parent, viewState: .init())
        store.setContainerIfNeeded(for: TestView())
        XCTAssertNil(store.pullbackAction)
        let uuid = UUID()
        store.pullback(to: /ParentReducer.Action.childId, parent: parent, id: uuid)
        store.sendIfNeeded(.c1)
        XCTAssertNotNil(store.pullbackAction)
        XCTAssertEqual(parent.store.container?.id, uuid)
    }

    func testPullbackReducerActionForId() throws {
        let parent = ParentView()
        parent.store.setContainerIfNeeded(for: parent, viewState: .init())
        store.setContainerIfNeeded(for: TestView())
        XCTAssertNil(store.pullbackReducerAction)
        let uuid = UUID()
        store.pullback(to: /ParentReducer.Action.childIdReducerAction, parent: parent, id: uuid)
        store.sendIfNeeded(.c4)
        XCTAssertNotNil(store.pullbackReducerAction)
        XCTAssertEqual(parent.store.container?.id, uuid)
    }

    func testIsNotUsingViewState() throws {
        let container = withDependencies {
            $0.isTesting = false
        } operation: {
            store.setContainerIfNeeded(for: TestView(), viewState: .init())
        }
        XCTAssertNil(container.viewState)
    }

    func testUsingViewState() throws {
        let container = withDependencies {
            $0.isTesting = true
        } operation: {
            store.setContainerIfNeeded(for: TestView(), viewState: .init())
        }
        XCTAssertNotNil(container.viewState)
    }

    func testSendIsNotTesting() async throws {
        let container = store.setContainerIfNeeded(for: TestView())
        await withDependencies {
            $0.isTesting = false
        } operation: {
            await store.sendAction(.action(.c3), container: container).wait()
        }
        XCTAssertEqual(store.sentFromEffectActions.count, 0)
    }

    func testSendIsTesting() async throws {
        let container = store.setContainerIfNeeded(for: TestView())
        await withDependencies {
            $0.isTesting = true
        } operation: {
            await store.sendAction(.action(.c3), container: container).wait()
        }
        XCTAssertEqual(store.sentFromEffectActions.count, 1)
    }
}

@ViewState
private struct ParentView: View {
    @State var count = 0
    @State var id: UUID?
    let store: Store<ParentReducer> = .init(reducer: ParentReducer())
    var body: some View {
        EmptyView()
    }
}

private struct ParentReducer: ReducerProtocol {
    enum Action {
        case child(TestReducer.Action)
        case childReducerAction(TestReducer.ReducerAction)
        case childId(id: UUID, action: TestReducer.Action)
        case childIdReducerAction(id: UUID, action: TestReducer.ReducerAction)
    }

    func reduce(into state: StateContainer<ParentView>, action: Action) -> SideEffect<ParentReducer> {
        switch action {
        case .child:
            state.count += 1
            return .none

        case .childReducerAction:
            state.count += 1
            return .none

        case .childId(let id, _):
            state.id = id
            return .none

        case .childIdReducerAction(let id, _):
            state.id = id
            return .none
        }
    }
}

private struct TestReducer: ReducerProtocol {
    enum ReducerAction: Equatable, Pullbackable {
        case c3
        case c4
    }

    enum Action: Equatable, Pullbackable {
        case c1
        case c2
    }

    func reduce(into _: StateContainer<TestView>, action: ReducerAction) -> SideEffect<TestReducer> {
        switch action {
        case .c3:
            return .send(.c4)

        case .c4:
            return .none
        }
    }

    func reduce(into _: StateContainer<TestView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .c1:
            return .none

        case .c2:
            return .send(.c3)
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
