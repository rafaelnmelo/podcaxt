import Foundation

struct Episode: Identifiable, Hashable {
    let id: UUID = .init()

    // MARK: - Required (Apple Podcast RSS)
    var title: String
    var enclosureURL: URL
    var enclosureMimeType: String
    var enclosureLength: Int
    var guid: String
    var isExplicit: Bool

    // MARK: - Recommended
    var description: String
    var pubDate: Date?
    var duration: TimeInterval?
    var imageURL: URL?
    var author: String?
    var season: Int?
    var episodeNumber: Int?
    var episodeType: EpisodeType
}

enum EpisodeType: String {
    case full
    case trailer
    case bonus
}
