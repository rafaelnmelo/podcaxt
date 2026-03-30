import Foundation
import Combine
import SwiftUI

enum RSSInputState: Equatable {
    case idle
    case loading
    case success(Podcast)
    case failure(String)
}

@MainActor
final class RSSInputViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published private(set) var state: RSSInputState = .idle
    @Published private(set) var history: [RSSFeedURL] = []
    @Published private(set) var historyImages: [URL: Image] = [:]
    @Published private(set) var historyTitles: [URL: String] = [:]

    var onSuccess: ((Podcast) -> Void)?

    private let rssService: any RSSFetching
    private let persistence: any FeedHistoryPersisting
    private let rssCache: any RSSCaching
    private let imageCache: any ImageCaching
    private let parser: any RSSParsing

    init(
        rssService: any RSSFetching = RSSService.shared,
        persistence: any FeedHistoryPersisting = PersistenceService.shared,
        rssCache: any RSSCaching = RSSCache.shared,
        imageCache: any ImageCaching = ImageCache.shared,
        parser: any RSSParsing = RSSParser()
    ) {
        self.rssService = rssService
        self.persistence = persistence
        self.rssCache = rssCache
        self.imageCache = imageCache
        self.parser = parser
    }

    /// Validates the current `urlText`, fetches the podcast and saves the URL to history.
    func submitURL() async {
        guard let url = URL.rss(from: urlText) else {
            state = .failure("URL Inválida")
            return
        }

        state = .loading
        do {
            let podcast = try await rssService.fetchPodcast(from: url)
            persistence.saveURL(url)
            reloadHistory()
            state = .success(podcast)
            onSuccess?(podcast)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    /// Loads the URL history from persistence and resolves metadata once.
    func loadHistory() {
        reloadHistory()
        Task { await resolveMetadata() }
    }

    /// Returns the cached `Podcast` for a given feed URL without hitting the network.
    func cachedPodcast(for url: URL) async -> Podcast? {
        guard let data = await rssCache.cachedData(for: url) else { return nil }
        return await Task.detached { [parser] in
            try? parser.parse(data)
        }.value
    }

    /// Selects a URL from history, populating `urlText` and triggering fetch.
    /// - Parameter feedURL: History entry to load.
    func select(_ feedURL: RSSFeedURL) async {
        urlText = feedURL.url.absoluteString
        await submitURL()
    }

    /// Removes a URL entry from history.
    /// - Parameter feedURL: History entry to remove.
    func removeFromHistory(_ feedURL: RSSFeedURL) {
        persistence.removeURL(feedURL.url)
        reloadHistory()
    }

    /// Clears all history entries.
    func clearHistory() {
        persistence.clearHistory()
        reloadHistory()
    }
}

// MARK: - Private

private extension RSSInputViewModel {
    func reloadHistory() {
        history = persistence.fetchHistory()
    }

    func resolveMetadata() async {
        for feedURL in history {
            guard historyTitles[feedURL.url] == nil else { continue }
            guard let podcast = await cachedPodcast(for: feedURL.url) else { continue }
            historyTitles[feedURL.url] = podcast.title
            if let data = await imageCache.cachedData(for: podcast.imageURL),
               let uiImage = UIImage(data: data) {
                historyImages[feedURL.url] = Image(uiImage: uiImage)
            }
        }
    }
}
