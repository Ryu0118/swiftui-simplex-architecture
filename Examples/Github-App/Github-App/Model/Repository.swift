import Foundation

struct Repository: Identifiable, Equatable, Hashable {
    let id: Int
    let url: String
    let fullName: String
    let avatarUrl: String
    let description: String?
    let language: String?
    let stargazersCount: Int

    init(item: Response.Item) {
        self.id = item.id
        self.url = item.svnUrl
        self.fullName = item.fullName
        self.avatarUrl = item.owner.avatarUrl
        self.description = item.description
        self.language = item.language
        self.stargazersCount = item.stargazersCount
    }
}

struct Response: Decodable {
    let items: [Item]

    struct Item: Decodable {
        let id: Int
        let svnUrl: String
        let owner: Owner
        let fullName: String
        let description: String?
        let language: String?
        let stargazersCount: Int

        struct Owner: Decodable {
            let avatarUrl: String
        }
    }
}
