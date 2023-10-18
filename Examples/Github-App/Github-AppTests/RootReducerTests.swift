@testable import Github_App
import SimplexArchitecture
import XCTest

@MainActor
final class RootReducerTests: XCTestCase {
    func testSearchButtonTapped() async {
        let store = makeStore(
            repositoryClient: RepositoryClient(
                fetchRepositories: { _ in [.stub] }
            )
        )

        await store.send(.onSearchButtonTapped) {
            $0.isLoading = true
        }
        await store.receive(.fetchRepositoriesResponse(.success([.stub]))) {
            $0.repositories = [.stub]
            $0.isLoading = false
        }
    }

    func testSearchButtonTappedWithFailure() async {
        let error = CancellationError()
        let store = makeStore(
            repositoryClient: RepositoryClient(
                fetchRepositories: { _ in throw error }
            )
        )

        await store.send(.onSearchButtonTapped) {
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

    func testTextChanged() async {
        let store = RootView().testStore(viewState: .init(repositories: [.stub]))
        await store.send(.onTextChanged("test"))
        await store.send(.onTextChanged("")) {
            $0.repositories = []
        }
    }

    func makeStore(repositoryClient: RepositoryClient) -> TestStore<RootReducer> {
        RootView().testStore(viewState: .init()) {
            $0.repositoryClient = repositoryClient
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
