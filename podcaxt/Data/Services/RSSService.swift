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

    init(cache: any RSSCaching = RSSCache.shared, parser: any RSSParsing = RSSParser()) {
        self.cache = cache
        self.parser = parser
    }

    /// Returns a parsed `Podcast` for the given RSS feed URL.
    /// Lookup order: cache → network.
    /// When fetched from network, raw data is stored in cache before parsing.
    /// - Parameter url: RSS feed URL.
    /// - Returns: Parsed `Podcast` with its episodes.
    func fetchPodcast(from url: URL) async throws -> Podcast {
        if let cached = await cache.cachedData(for: url) {
            return try await Task.detached { [parser] in
                try parser.parse(cached)
            }.value
        }

        let (data, _) = try await URLSession.shared.debugData(from: url)
        try? await cache.cache(data, for: url)
        return try await Task.detached { [parser] in
            try parser.parse(data)
        }.value
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
