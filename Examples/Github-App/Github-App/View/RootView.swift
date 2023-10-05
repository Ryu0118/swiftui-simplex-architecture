import SwiftUI
import SimplexArchitecture

struct RootReducer: ReducerProtocol {
    enum Action: Equatable {
        case onSearchButtonTapped
        case onTextChanged(String)
    }

    enum ReducerAction: Equatable {
        case fetchRepositoriesResponse(TaskResult<[Repository]>)
        case alert(Alert)

        enum Alert: Equatable {
            case retry
        }
    }

    @Dependency(\.repositoryClient.fetchRepositories) var fetchRepositories

    func reduce(
        into state: StateContainer<RootView>,
        action: ReducerAction
    ) -> SideEffect<RootReducer> {
        switch action {
        case let .fetchRepositoriesResponse(.success(repositories)):
            state.isLoading = false
            state.repositories = repositories
            return .none

        case let .fetchRepositoriesResponse(.failure(error)):
            state.isLoading = false
            state.alertState = .init {
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
            return .none

        case .alert(.retry):
            state.isLoading = true
            return fetchRepositories(query: state.text)
        }
    }

    func reduce(
        into state: StateContainer<RootView>,
        action: Action
    ) -> SideEffect<Self> {
        switch action {
        case .onSearchButtonTapped:
            state.isLoading = true
            return fetchRepositories(query: state.text)

        case .onTextChanged(let text):
            if text.isEmpty {
                state.repositories = []
            }
            return .none
        }
    }

    func fetchRepositories(query: String) -> SideEffect<Self> {
        .run { send in
            await send(
                .fetchRepositoriesResponse(
                    TaskResult { try await fetchRepositories(query) }
                )
            )
        }
    }
}

@ViewState
struct RootView: View {
    @State var text = ""
    @State var isLoading = false
    @State var repositories: [Repository] = []
    @State var alertState: AlertState<Reducer.ReducerAction>?

    let store: Store<RootReducer> = Store(reducer: RootReducer())

    var body: some View {
        NavigationStack {
            List {
                ForEach(repositories) { repository in
                    NavigationLink(repository.fullName) {
                        RepositoryView(repository: repository)
                            .navigationTitle(repository.fullName)
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .searchable(text: $text)
            .onSubmit(of: .search) {
                send(.onSearchButtonTapped)
            }
            .onChange(of: text) { _, newValue in
                send(.onTextChanged(newValue))
            }
            .alert(target: self, unwrapping: $alertState)
        }
    }
}

#Preview {
    RootView()
}