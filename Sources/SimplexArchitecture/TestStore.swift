import CasePaths
import CustomDump
import Dependencies
import Foundation

public final class TestStore<Reducer: ReducerProtocol> where Reducer.Action: Equatable, Reducer.ReducerAction: Equatable {
    var runningContainer: StateContainer<Reducer.Target>?
    var testedActions: [ActionTransition<Reducer>] = []

    var untestedActions: [ActionTransition<Reducer>] {
        target.store.sentFromEffectActions.filter { actionTransition in
            !testedActions.contains {
                String(customDumping: $0) == String(customDumping: actionTransition)
            }
        }
    }

    let target: Reducer.Target
    let states: Reducer.Target.States

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

            if let firstIndex = untestedActions.firstIndex(where: { $0.action == action }),
               let stateTransition = untestedActions[safe: firstIndex]
            {
                let expectedContainer = stateTransition.toNextStateContainer(from: target)
                let actualContainer = stateTransition.toPreviousStateContainer(from: target)

                expected?(actualContainer)

                assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
                assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

                testedActions.append(stateTransition)
                break
            }

            await Task.yield()
        }
    }

    func receiveWithoutStateCheck(
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

            if let firstIndex = untestedActions.firstIndex(where: { $0.action == .action(action) }),
               let stateTransition = untestedActions[safe: firstIndex]
            {
                testedActions.append(stateTransition)
                break
            }

            await Task.yield()
        }
    }

    @MainActor
    public func send(
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

        await Task.megaYield()
    }

    @MainActor
    public func send(
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async where Reducer.Target.States: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

        await Task.megaYield()
    }

    @MainActor
    public func send(
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async where Reducer.ReducerState: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: expectedContainer, actual: actualContainer)
        assertReducerNoDifference(expected: expectedContainer, actual: actualContainer)

        await Task.megaYield()
    }

    @MainActor
    public func send(
        _ action: Reducer.Action,
        assert expected: ((StateContainer<Reducer.Target>) -> Void)? = nil
    ) async where Reducer.ReducerState: Equatable, Reducer.Target.States: Equatable {
        let expectedContainer = target.store.setContainerIfNeeded(for: target, states: states)
        runningContainer = expectedContainer
        let actualContainer = expectedContainer.copy()

        target.store.sendIfNeeded(action)

        expected?(actualContainer)

        assertStatesNoDifference(expected: actualContainer, actual: actualContainer)
        assertReducerNoDifference(expected: actualContainer, actual: actualContainer)

        await Task.megaYield()
    }
}

// MARK: - +Assert

private extension TestStore {
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
    func testStore(states: States) -> TestStore<Reducer> {
        TestStore(target: self, states: states)
    }
}
