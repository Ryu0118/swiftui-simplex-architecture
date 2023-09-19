import CasePaths
import CustomDump
import Dependencies
import Foundation

/// TestStore is a utility class for testing stores that use Reducer protocols.
/// It provides methods for sending actions and verifying state changes.
public final class TestStore<Reducer: ReducerProtocol> where Reducer.Action: Equatable, Reducer.ReducerAction: Equatable {

    // MARK: - Properties

    /// The running state container.
    var runningContainer: StateContainer<Reducer.Target>?

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

    let target: Reducer.Target

    /// The states of the target.
    let states: Reducer.Target.States

    /// Initializes a new test store.
    ///
    /// - Parameters:
    ///   - target: The target Reducer.
    ///   - states: The states of the target Reducer.
    init(
        target: Reducer.Target,
        states: Reducer.Target.States
    ) {
        self.target = target
        self.states = states
    }

    deinit {
        if untestedActions.count > 0 {
            let unhandledActionStrings = untestedActions
                .map {
                    switch $0.action.kind {
                    case let .viewAction(action):
                        String(customDumping: action)
                    case let .reducerAction(action):
                        String(customDumping: action)
                    }
                }
                .joined(separator: ", ")

            XCTFail(
                """
                Unhandled Action remains. Use TestStore.receive to implement tests of \(unhandledActionStrings)
                """
            )
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
        await receive(
            .action(action),
            timeout: timeout,
            expected: expected,
            file: file,
            line: line
        )
    }

    /// Asserts an action was received from an effect and asserts how the state changes.
    ///
    /// - Parameters:
    ///   - action: An action expected from an effect.
    ///   - timeout: The amount of time to wait for the expected action.
    ///   - expected: A closure that asserts state changed by sending the action to the store. The mutable state sent to this closure must be modified to match the state of the store after processing the given action. Do not provide a closure if no change is expected.
    @_disfavoredOverload
    public func receive(
        _ action: Reducer.ReducerAction,
        timeout: TimeInterval = 5,
        expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await receive(
            .action(action),
            timeout: timeout,
            expected: expected,
            file: file,
            line: line
        )
    }

    private func receive(
        _ action: CombineAction<Reducer>,
        timeout: TimeInterval = 5,
        expected: ((StateContainer<Reducer.Target>) -> Void)? = nil,
        file: StaticString,
        line: UInt
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
                let expectedContainer = stateTransition.asNextStateContainer(from: target)
                let actualContainer = stateTransition.asPreviousStateContainer(from: target)

                expected?(actualContainer)

                assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
                assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

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

            if let stateTransition = untestedActions.first(where: { $0.action == .action(action) }) {
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
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async -> SendTask {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

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
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async -> SendTask where Reducer.Target.States: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

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
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async -> SendTask where Reducer.ReducerState: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

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
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async -> SendTask where Reducer.ReducerState: Equatable, Reducer.Target.States: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        let sendTask = target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: actualContainer, actual: actualContainer)
        assertReducerNoDifference(expected: actualContainer, actual: actualContainer)

        await Task.megaYield()

        return sendTask
    }
}

extension TestStore {
    private func assertStatesNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>
    ) where Reducer.Target.States: Equatable {
        if let expectedStates = expectedContainer.states,
           let actualStates = actualContainer.states
        {
            XCTAssertNoDifference(expectedStates, actualStates)
        }
    }

    private func assertStatesNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>
    ) {
        if let expectedStates = expectedContainer.states,
           let actualStates = actualContainer.states
        {
            let expectedDump = String(customDumping: expectedStates)
            let actualDump = String(customDumping: actualStates)
            XCTAssertNoDifference(expectedDump, actualDump)
        }
    }

    private func assertReducerStateNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>
    ) where Reducer.ReducerState: Equatable {
        if let expected = expectedContainer._reducerState,
           let actual = actualContainer._reducerState
        {
            XCTAssertNoDifference(expected, actual)
        }
    }

    private func assertReducerNoDifference(
        expected expectedContainer: StateContainer<Reducer.Target>,
        actual actualContainer: StateContainer<Reducer.Target>
    ) {
        if let expected = expectedContainer._reducerState,
           let actual = actualContainer._reducerState
        {
            let expectedDump = String(customDumping: expected)
            let actualDump = String(customDumping: actual)
            XCTAssertNoDifference(expectedDump, actualDump)
        }
    }
}

public extension ActionSendable where Reducer.Action: Equatable, Reducer.ReducerAction: Equatable {
    /// Creates and returns a new test store.
    ///
    /// - Parameter states: The initial states for testing.
    /// - Returns: A new TestStore instance.
    func testStore(states: States) -> TestStore<Reducer> {
        TestStore(target: self, states: states)
    }
}
