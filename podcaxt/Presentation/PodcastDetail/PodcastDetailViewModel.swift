import Foundation
import Combine

@MainActor
final class PodcastDetailViewModel: ObservableObject {
    @Published private(set) var podcast: Podcast

    private let rssService: any RSSFetching
    private let feedURL: URL

    init(
        podcast: Podcast,
        feedURL: URL,
        rssService: any RSSFetching = RSSService.shared
    ) {
        self.podcast = podcast
        self.feedURL = feedURL
        self.rssService = rssService
    }

    /// Refreshes the podcast by invalidating the cache and re-fetching the feed.
    func refresh() async {
        try? await rssService.invalidateCache(for: feedURL)
        guard let refreshed = try? await rssService.fetchPodcast(from: feedURL) else { return }
        podcast = refreshed
    }

    /// Returns a formatted duration string for a given episode.
    /// - Parameter episode: The episode to format.
    func formattedDuration(for episode: Episode) -> String? {
        guard let duration = episode.duration else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration)
    }
}
