import Foundation

struct Podcast: Identifiable, Hashable {
    let id: UUID = .init()

    // MARK: - Required (Apple Podcast RSS)
    var title: String
    var link: URL
    var language: String
    var imageURL: URL
    var category: PodcastCategory
    var isExplicit: Bool

    // MARK: - Recommended
    var description: String
    var author: String
    var episodes: [Episode]
}

struct PodcastCategory: Hashable {
    var name: String
    var subcategory: String?
}
