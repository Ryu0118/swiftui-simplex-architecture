import SimplexArchitecture
import SwiftUI

@Reducer
struct RootReducer {
    enum ViewAction: Equatable {
        case textChanged
    }

    enum ReducerAction: Equatable {
        case fetchRepositoriesResponse(TaskResult<[Repository]>)
        case alert(Alert)
        case queryChangeDebounced

        enum Alert: Equatable {
            case retry
        }
    }

    enum CancelID {
        case response
    }

    @Dependency(\.repositoryClient.fetchRepositories) var fetchRepositories
    @Dependency(\.continuousClock) var clock

    func reduce(into state: StateContainer<RootView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .textChanged:
            if state.searchText.isEmpty {
                state.repositories = []
                return .none
            } else {
                return .send(.queryChangeDebounced)
                    .debounce(
                        id: CancelID.response,
                        for: .seconds(0.3),
                        clock: clock
                    )
            }

        case .queryChangeDebounced:
            guard !state.searchText.isEmpty else {
                return .none
            }
            state.isLoading = true
            return fetchRepositories(query: state.searchText)

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
            return fetchRepositories(query: state.searchText)
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
    @State var searchText = ""
    @State var isLoading = false
    @State var repositories: [Repository] = []
    @State var alertState: AlertState<Reducer.Action>?

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
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer
            )
            .onChange(of: searchText) { _, _ in
                send(.textChanged)
            }
            .alert(target: self, unwrapping: $alertState)
        }
    }
}

#Preview {
    RootView()
}
