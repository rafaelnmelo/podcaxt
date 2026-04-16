import Foundation

protocol FeedHistoryPersisting {
    func fetchHistory() -> [RSSFeedURL]
    func saveURL(_ url: URL)
    func removeURL(_ url: URL)
    func clearHistory()
}

final class PersistenceService: FeedHistoryPersisting {
    static let shared = PersistenceService()

    private let key = Strings.Persistence.rssFeedHistoryKey
    private let defaults: UserDefaults

    /// Creates a PersistenceService instance with the specified UserDefaults.
    /// - Parameter defaults: UserDefaults instance to use for storage. Defaults to standard UserDefaults.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Returns the URL history sorted by most recently used.
    /// Returns an empty array if no history is found or decoding fails.
    func fetchHistory() -> [RSSFeedURL] {
        guard
            let data = defaults.data(forKey: key),
            let history = try? JSONDecoder().decode([RSSFeedURL].self, from: data)
        else { return [] }
        return history.sorted { $0.lastUsed > $1.lastUsed }
    }

    /// Saves a URL to history, moving it to the top if it already exists.
    /// - Parameter url: RSS feed URL to save.
    func saveURL(_ url: URL) {
        var history = fetchHistory().filter { $0.url != url }
        history.insert(RSSFeedURL(url: url), at: 0)
        persist(history)
    }

    /// Removes a specific URL from history.
    /// - Parameter url: RSS feed URL to remove.
    func removeURL(_ url: URL) {
        persist(fetchHistory().filter { $0.url != url })
    }

    /// Clears the entire URL history from UserDefaults.
    func clearHistory() {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Private

private extension PersistenceService {
    /// Encodes and writes the given history array to UserDefaults.
    func persist(_ history: [RSSFeedURL]) {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: key)
        }
    }
}
