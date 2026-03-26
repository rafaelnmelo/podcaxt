import Foundation

struct RSSFeedURL: Identifiable, Hashable, Codable {
    let id: UUID
    var url: URL
    var lastUsed: Date

    init(url: URL) {
        self.id = .init()
        self.url = url
        self.lastUsed = .now
    }
}
