import SwiftUI
import SimplexArchitecture

@Reducer
struct RepositoryReducer {
    enum ViewAction {
        case onOpenURLButtonTapped
    }

    @Dependency(\.openURL) private var openURL

    func reduce(
        into state: StateContainer<RepositoryView>,
        action: Action
    ) -> SideEffect<RepositoryReducer> {
        switch action {
        case .onOpenURLButtonTapped:
            return .run { _ in
                await openURL(URL(string: state.repository.url)!)
            }
        }
    }
}

@ViewState
struct RepositoryView: View {
    @State var repository: Repository

    let store: Store<RepositoryReducer> = Store(reducer: RepositoryReducer())

    init(repository: Repository) {
        self.repository = repository
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
