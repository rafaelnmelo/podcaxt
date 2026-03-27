import Foundation

protocol RSSCaching: Actor {
    func cachedData(for url: URL) -> Data?
    func cache(_ data: Data, for url: URL) throws
    func invalidateCache(for url: URL) throws
    func clearCache() throws
}

actor RSSCache: RSSCaching {
    static let shared = RSSCache()

    private let ttl: TimeInterval
    private let diskURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RSSCache", isDirectory: true)
    }()

    /// Sets the TTL and creates the disk cache directory if needed.
    init(ttl: TimeInterval = 60 * 30) {
        self.ttl = ttl
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns cached RSS `Data` for the given URL if it exists and has not expired.
    /// Returns `nil` if the entry is missing or older than the TTL.
    /// - Parameter url: RSS feed URL used as cache key.
    func cachedData(for url: URL) -> Data? {
        let file = cacheFile(for: url)
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
            let modified = attrs[.modificationDate] as? Date,
            Date().timeIntervalSince(modified) < ttl,
            let data = try? Data(contentsOf: file)
        else { return nil }
        return data
    }

    /// Writes RSS `Data` to disk for the given URL.
    /// - Parameters:
    ///   - data: Raw RSS feed data to cache.
    ///   - url: RSS feed URL used as cache key.
    /// - Throws: `FileManager` error if the write fails.
    func cache(_ data: Data, for url: URL) throws {
        try data.write(to: cacheFile(for: url))
    }

    /// Removes the cached entry for a specific feed URL.
    /// - Parameter url: RSS feed URL whose cache entry should be removed.
    /// - Throws: `FileManager` error if the file cannot be removed.
    func invalidateCache(for url: URL) throws {
        try FileManager.default.removeItem(at: cacheFile(for: url))
    }

    /// Removes all cached RSS feed data and recreates the empty cache directory.
    /// - Throws: `FileManager` error if removal or recreation of the directory fails.
    func clearCache() throws {
        try FileManager.default.removeItem(at: diskURL)
        try FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    private func cacheFile(for url: URL) -> URL {
        diskURL.appendingPathComponent(url.absoluteString.hash.description)
    }
}
