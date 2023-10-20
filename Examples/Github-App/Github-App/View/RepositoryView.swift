import SimplexArchitecture
import SwiftUI

@Reducer
struct RepositoryReducer {
    enum ViewAction {
        case onOpenURLButtonTapped
    }

    struct ReducerState {
        let url: String
    }

    @Dependency(\.openURL) private var openURL

    func reduce(
        into state: StateContainer<RepositoryView>,
        action: Action
    ) -> SideEffect<RepositoryReducer> {
        switch action {
        case .onOpenURLButtonTapped:
            return .run { _ in
                await openURL(URL(string: state.reducerState.url)!)
            }
        }
    }
}

@ViewState
struct RepositoryView: View {
    let store: Store<RepositoryReducer>
    let repository: Repository

    init(repository: Repository) {
        self.repository = repository
        self.store = Store(
            reducer: RepositoryReducer(),
            initialReducerState: RepositoryReducer.ReducerState(url: repository.url)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack {
                    AsyncImage(url: URL(string: repository.avatarUrl)!)
                    if let description = repository.description {
                        Text(description)
                            .font(.headline)
                    }
                }

                VStack(alignment: .leading) {
                    Text("star: \(repository.stargazersCount)")
                    Text("language: \(repository.language ?? "unknown")")
                }
                .font(.subheadline)

                Button {
                    send(.onOpenURLButtonTapped)
                } label: {
                    Text("Open GitHub URL")
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
