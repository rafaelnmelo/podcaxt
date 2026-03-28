import Foundation

enum RSSInputState {
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

    private let rssService: any RSSFetching
    private let persistence: any FeedHistoryPersisting

    init(
        rssService: any RSSFetching = RSSService.shared,
        persistence: any FeedHistoryPersisting = PersistenceService.shared
    ) {
        self.rssService = rssService
        self.persistence = persistence
    }

    /// Validates the current `urlText`, fetches the podcast and saves the URL to history.
    func submitURL() async {
        guard let url = URL.rss(from: urlText) else {
            state = .failure("Invalid URL")
            return
        }

        state = .loading
        do {
            let podcast = try await rssService.fetchPodcast(from: url)
            persistence.saveURL(url)
            reloadHistory()
            state = .success(podcast)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    /// Loads the URL history from persistence.
    func loadHistory() {
        reloadHistory()
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
}
