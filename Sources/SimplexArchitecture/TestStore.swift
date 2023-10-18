import CasePaths
import CustomDump
import Dependencies
import Foundation

/// TestStore is a utility class for testing stores that use Reducer protocols.
/// It provides methods for sending actions and verifying state changes.
public final class TestStore<Reducer: ReducerProtocol> where Reducer.Action: Equatable {
    /// The running state container.
    var runningContainer: StateContainer<Reducer.Target>?

    /// The running tasks
    var runningTasks: [SendTask] = []

    /// An array of tested actions.
    var testedActions: [ActionTransition<Reducer>] = []

    /// An array of untested actions.
    var untestedActions: [ActionTransition<Reducer>] {
        target.store.sentFromEffectActions.filter { actionTransition in
            !testedActions.contains {
                String(customDumping: $0) == String(customDumping: actionTransition)
            }
        }
    }

    let updateValuesForOperation: (inout DependencyValues) -> Void
    let target: Reducer.Target

    /// The viewState of the target.
    let viewState: Reducer.Target.ViewState

    /// Initializes a new test store.
    ///
    /// - Parameters:
    ///   - target: The target Reducer.
    ///   - viewState: The viewState of the target Reducer.
    init(
        target: Reducer.Target,
        viewState: Reducer.Target.ViewState,
        withDependencies updateValuesForOperation: @escaping (inout DependencyValues) -> Void
    ) {
        self.target = target
        self.viewState = viewState
        self.updateValuesForOperation = updateValuesForOperation
    }

    deinit {
        if untestedActions.count > 0 {
            let unhandledActionStrings = untestedActions
                .map { String(customDumping: $0.action) }
                .joined(separator: ", ")

            XCTFail(
                """
                Unhandled Action remains. Use TestStore.receive to implement tests of \(unhandledActionStrings)
                """
            )
        }
    }

    /// Wait for all of the TestStore's remaining SendTasks to complete.
    public func waitForAll() async {
        await withTaskGroup(of: Void.self) { group in
            for task in runningTasks {
                group.addTask {
                    await task.wait()
                }
            }
            await group.waitForAll()
        }
    }

    /// Asserts an action was received from an effect and asserts how the state changes.
    ///
    /// - Parameters:
    ///   - action: An action expected from an effect.
    ///   - timeout: The amount of time to wait for the expected action.
    ///   - expected: A closure that asserts state changed by sending the action to the store. The mutable state sent to this closure must be modified to match the state of the store after processing the given action. Do not provide a closure if no change is expected.
    public func receive(
        _ action: Reducer.Action,
        timeout: TimeInterval = 5,
        expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        guard let _ = runningContainer else {
            XCTFail(
                """
                Action has not been sent. Please invoke TestStore.send(_:)
                """,
                file: file,
                line: line
            )
            return
        }

        let start = Date()

        while !Task.isCancelled {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail(
                    "Store.receive has timed out.",
                    file: file,
                    line: line
                )
                break
            }

            if let stateTransition = untestedActions.first(where: { $0.action == action }) {
                let expectedContainer = stateTransition.asNextStateContainer(from: target)
                let actualContainer = stateTransition.asPreviousStateContainer(from: target)

                expected?(actualContainer)

                assertViewStateNoDifference(
                    expected: expectedContainer,
                    actual: actualContainer,
                    file: file,
                    line: line
                )
                assertReducerStateNoDifference(
                    expected: expectedContainer,
                    actual: actualContainer,
                    file: file,
                    line: line
                )

                testedActions.append(stateTransition)
                break
            }

            await Task.yield()
        }
    }

    /// Asserts an action was received from an effect. Does not assert state changes.
    public func receiveWithoutStateCheck(
        _ action: Reducer.Action,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        guard let _ = runningContainer else {
            XCTFail(
                """
                Action has not been sent. Please invoke TestStore.send(_:)
                """
            )
            return
        }

        let start = Date()

        while !Task.isCancelled {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail(
                    "Store.receive has timed out.",
                    file: file,
                    line: line
                )
                break
            }

            if let stateTransition = untestedActions.first(where: { $0.action == action }) {
                testedActions.append(stateTransition)
                break
            }

            await Task.yield()
        }
    }

    /// Sends an action to the store and asserts when state changes.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - assert: A closure that asserts state changed by sending the action to
    ///     the store. The mutable state sent to this closure must be modified to match the state of
    ///     the store after processing the given action. Do not provide a closure if no change is
    ///     expected.
    /// - Returns: A ``SendTask`` that represents the lifecycle of the effect executed when
    ///   sending the action.
    @discardableResult
    @MainActor
    public func send(
        _ action: Reducer.ViewAction,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> SendTask {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, viewState: viewState)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = withDependencies(updateValuesForOperation) {
            target.store.send(action, target: target)
        }
        runningTasks.append(sendTask)

        expected?(actualContainer)

        assertViewStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )
        assertReducerStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )

        await Task.megaYield()
        return sendTask
    }

    /// Sends an action to the store and asserts when state changes.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - assert: A closure that asserts state changed by sending the action to
    ///     the store. The mutable state sent to this closure must be modified to match the state of
    ///     the store after processing the given action. Do not provide a closure if no change is
    ///     expected.
    /// - Returns: A ``SendTask`` that represents the lifecycle of the effect executed when
    ///   sending the action.
    @discardableResult
    @MainActor
    public func send(
        _ action: Reducer.ViewAction,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> SendTask where Reducer.Target.ViewState: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, viewState: viewState)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = withDependencies(updateValuesForOperation) {
            target.store.send(action, target: target)
        }
        runningTasks.append(sendTask)

        expected?(actualContainer)

        assertViewStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )
        assertReducerStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )

        await Task.megaYield()

        return sendTask
    }

    /// Sends an action to the store and asserts when state changes.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - assert: A closure that asserts state changed by sending the action to
    ///     the store. The mutable state sent to this closure must be modified to match the state of
    ///     the store after processing the given action. Do not provide a closure if no change is
    ///     expected.
    /// - Returns: A ``SendTask`` that represents the lifecycle of the effect executed when
    ///   sending the action.
    @discardableResult
    @MainActor
    public func send(
        _ action: Reducer.ViewAction,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> SendTask where Reducer.ReducerState: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, viewState: viewState)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = withDependencies(updateValuesForOperation) {
            target.store.send(action, target: target)
        }
        runningTasks.append(sendTask)

        expected?(actualContainer)

        assertViewStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )
        assertReducerStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )

        await Task.megaYield()
        return sendTask
    }

    /// Sends an action to the store and asserts when state changes.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - assert: A closure that asserts state changed by sending the action to
    ///     the store. The mutable state sent to this closure must be modified to match the state of
    ///     the store after processing the given action. Do not provide a closure if no change is
    ///     expected.
    /// - Returns: A ``SendTask`` that represents the lifecycle of the effect executed when
    ///   sending the action.
    @discardableResult
    @MainActor
    public func send(
        _ action: Reducer.ViewAction,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> SendTask where Reducer.ReducerState: Equatable, Reducer.Target.ViewState: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, viewState: viewState)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = withDependencies(updateValuesForOperation) {
            target.store.send(action, target: target)
        }
        runningTasks.append(sendTask)

        expected?(actualContainer)

        assertViewStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )
        assertReducerStateNoDifference(
            expected: expectedContainer,
            actual: actualContainer,
            file: file,
            line: line
        )

        await Task.megaYield()

        return sendTask
    }
}

extension TestStore {
    private func assertViewStateNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>,
        file: StaticString,
        line: UInt
    ) where Reducer.Target.ViewState: Equatable {
        if let expectedViewState = expectedContainer.viewState,
           let actualViewState = actualContainer.viewState
        {
            XCTAssertNoDifference(
                expectedViewState,
                actualViewState,
                file: file,
                line: line
            )
        }
    }

    private func assertViewStateNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>,
        file: StaticString,
        line: UInt
    ) {
        if let expectedViewState = expectedContainer.viewState,
           let actualViewState = actualContainer.viewState
        {
            let expectedDump = String(customDumping: expectedViewState)
            let actualDump = String(customDumping: actualViewState)
            XCTAssertNoDifference(
                expectedDump,
                actualDump,
                file: file,
                line: line
            )
        }
    }

    private func assertReducerStateNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>,
        file: StaticString,
        line: UInt
    ) where Reducer.ReducerState: Equatable {
        if let expected = expectedContainer._reducerState,
           let actual = actualContainer._reducerState
        {
            XCTAssertNoDifference(
                expected,
                actual,
                file: file,
                line: line
            )
        }
    }

    private func assertReducerStateNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>,
        file: StaticString,
        line: UInt
    ) {
        if let expected = expectedContainer._reducerState,
           let actual = actualContainer._reducerState
        {
            let expectedDump = String(customDumping: expected)
            let actualDump = String(customDumping: actual)
            XCTAssertNoDifference(
                expectedDump,
                actualDump,
                file: file,
                line: line
            )
        }
    }
}

public extension ActionSendable where Reducer.Action: Equatable {
    /// Creates and returns a new test store.
    ///
    /// - Parameters:
    ///   - viewState: The initial viewState for testing.
    ///   - withDependencies: A closure for updating the current dependency values
    /// - Returns: TestStore instance.
    func testStore(
        viewState: ViewState,
        withDependencies updateValuesForOperation: @escaping (inout DependencyValues) -> Void = { _ in }
    ) -> TestStore<Reducer> {
        TestStore(target: self, viewState: viewState, withDependencies: updateValuesForOperation)
    }
}
