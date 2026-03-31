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
    private let imageService: any ImageFetching
    private let parser: any RSSParsing

    init(
        rssService: any RSSFetching = RSSService.shared,
        persistence: any FeedHistoryPersisting = PersistenceService.shared,
        rssCache: any RSSCaching = RSSCache.shared,
        imageService: any ImageFetching = ImageService.shared,
        parser: any RSSParsing = RSSParser()
    ) {
        self.rssService = rssService
        self.persistence = persistence
        self.rssCache = rssCache
        self.imageService = imageService
        self.parser = parser
    }

    /// Validates the current `urlText`, fetches the podcast and saves the URL to history.
    func submitURL() async {
        guard let url = URL.rss(from: urlText) else {
            state = .failure(Strings.RSSInput.invalidURL)
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
    /// Reloads history from persistence into the `history` published property.
    func reloadHistory() {
        history = persistence.fetchHistory()
    }

    /// Resolves title and cover image for each history entry that hasn't been loaded yet.
    /// Reads from `.meta` cache when available; falls back to XML parse otherwise.
    func resolveMetadata() async {
        for feedURL in history {
            guard historyTitles[feedURL.url] == nil else { continue }
            guard let metadata = await resolvedMetadata(for: feedURL.url) else { continue }
            historyTitles[feedURL.url] = metadata.title
            if let data = try? await imageService.fetchImage(from: metadata.imageURL),
               let uiImage = UIImage(data: data) {
                historyImages[feedURL.url] = Image(uiImage: uiImage)
            }
        }
    }

    /// Returns metadata from `.meta` cache if available, otherwise parses the XML cache as fallback
    /// and persists the metadata for future calls.
    func resolvedMetadata(for url: URL) async -> PodcastMetadata? {
        if let metadata = await rssCache.cachedMetadata(for: url) { return metadata }
        guard let data = await rssCache.cachedData(for: url),
              let podcast = await Task.detached(operation: { [parser] in 
                  try? parser.parse(data) }).value
        else { return nil }
        let metadata = PodcastMetadata(title: podcast.title, imageURL: podcast.imageURL)
        try? await rssCache.cacheMetadata(metadata, for: url)
        return metadata
    }
}
