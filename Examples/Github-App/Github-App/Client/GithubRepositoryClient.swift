import Foundation
import Dependencies
import DependenciesMacro

@Dependencies
struct RepositoryClient {
    var fetchRepositories: @Sendable (_ query: String) async throws -> [Repository]
}

extension RepositoryClient: DependencyKey {
    static let liveValue: RepositoryClient = RepositoryClient(
        fetchRepositories: { query in
            var component = URLComponents()
            component.scheme = "https"
            component.host = "api.github.com"
            component.path = "/search/repositories"
            component.queryItems = [
                URLQueryItem(name: "q", value: query)
            ]

            guard let url = component.url else {
                return []
            }

            let request = URLRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(Response.self, from: data)

            return response.items.map { Repository(item: $0) }
        }
    )
}

@DependencyValue(RepositoryClient.self)
extension DependencyValues {}
