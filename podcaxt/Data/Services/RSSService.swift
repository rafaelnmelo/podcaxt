import Foundation

protocol RSSFetching {
    func fetchPodcast(from url: URL) async throws -> Podcast
    func invalidateCache(for url: URL) async throws
    func clearCache() async throws
}

final class RSSService: RSSFetching {
    static let shared = RSSService()

    private let cache: any RSSCaching
    private let parser: any RSSParsing

    /// Creates an RSSService instance with the specified cache and parser.
    /// - Parameters:
    ///   - cache: Cache implementation to use for storing RSS data. Defaults to shared RSSCache.
    ///   - parser: Parser implementation to use for parsing RSS feeds. Defaults to RSSParser.
    init(cache: any RSSCaching = RSSCache.shared, parser: any RSSParsing = RSSParser()) {
        self.cache = cache
        self.parser = parser
    }

    /// Returns a parsed `Podcast` for the given RSS feed URL.
    /// Lookup order: cache → network. Network responses are cached before parsing.
    /// - Parameter url: RSS feed URL.
    /// - Returns: Parsed `Podcast` with its episodes.
    func fetchPodcast(from url: URL) async throws -> Podcast {
        if let cached = await cache.cachedData(for: url) {
            return try await parse(cached)
        }
        return try await fetchAndCache(url)
    }

    /// Removes the cached data for a specific feed URL.
    /// - Parameter url: RSS feed URL to invalidate.
    func invalidateCache(for url: URL) async throws {
        try await cache.invalidateCache(for: url)
    }

    /// Removes all cached RSS feed data.
    func clearCache() async throws {
        try await cache.clearCache()
    }
}

// MARK: - Private

private extension RSSService {
    /// Parses raw RSS `Data` off the main thread.
    func parse(_ data: Data) async throws -> Podcast {
        try await Task.detached { [parser] in try parser.parse(data) }.value
    }

    /// Downloads the feed, writes it to cache, parses it and stores the metadata.
    func fetchAndCache(_ url: URL) async throws -> Podcast {
        let (data, _) = try await URLSession.shared.debugData(from: url)
        try? await cache.cache(data, for: url)
        let podcast = try await parse(data)
        try? await cache.cacheMetadata(PodcastMetadata(title: podcast.title, imageURL: podcast.imageURL), for: url)
        return podcast
    }
}
