@testable import Github_App
import SimplexArchitecture
import XCTest

@MainActor
final class RootReducerTests: XCTestCase {
    func testTextChanged() async {
        let store = RootView().testStore(viewState: .init(searchText: "text")) {
            $0.repositoryClient.fetchRepositories = { _ in [.stub] }
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.textChanged)
        await store.receive(.queryChangeDebounced) {
            $0.isLoading = true
        }
        await store.receive(.fetchRepositoriesResponse(.success([.stub]))) {
            $0.repositories = [.stub]
            $0.isLoading = false
        }
    }

    func testTextChangedWithFailure() async {
        let error = CancellationError()
        let store = RootView().testStore(viewState: .init(searchText: "text")) {
            $0.repositoryClient.fetchRepositories = { _ in throw error }
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.textChanged)
        await store.receive(.queryChangeDebounced) {
            $0.isLoading = true
        }
        await store.receive(.fetchRepositoriesResponse(.failure(error))) {
            $0.isLoading = false
            $0.alertState = .init {
                TextState("An Error has occurred.")
            } actions: {
                ButtonState {
                    TextState("OK")
                }
                ButtonState(action: .alert(.retry)) {
                    TextState("Retry")
                }
            } message: {
                TextState(error.localizedDescription)
            }
        }
    }

    func testEmptyTextChanged() async {
        let store = RootView().testStore(viewState: .init(repositories: [.stub]))
        await store.send(.textChanged) {
            $0.repositories = []
        }
    }
}

extension Repository {
    static let stub = Repository(
        item: Response.Item(
            id: 0,
            svnUrl: "https://github.com/Ryu0118",
            owner: .init(avatarUrl: "https://github.com/Ryu0118.png"),
            fullName: "",
            description: "",
            language: "",
            stargazersCount: 0
        )
    )
}
