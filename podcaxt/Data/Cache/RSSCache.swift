import Foundation

struct PodcastMetadata: Codable {
    let title: String
    let imageURL: URL
}

protocol RSSCaching: Actor {
    func cachedData(for url: URL) -> Data?
    func cache(_ data: Data, for url: URL) throws
    func cachedMetadata(for url: URL) -> PodcastMetadata?
    func cacheMetadata(_ metadata: PodcastMetadata, for url: URL) throws
    func invalidateCache(for url: URL) throws
    func clearCache() throws
    func diskCacheSize() -> Int
}

actor RSSCache: RSSCaching {
    static let shared = RSSCache()

    private let disk = DiskCache(directory: Strings.Cache.rssCacheDirectory)

    /// Returns cached RSS `Data` for the given URL, or `nil` if not found.
    /// - Parameter url: RSS feed URL used as cache key.
    func cachedData(for url: URL) -> Data? {
        disk.read(for: url)
    }

    /// Writes RSS `Data` to disk for the given URL.
    /// - Throws: `FileManager` error if the write fails.
    func cache(_ data: Data, for url: URL) throws {
        try disk.write(data, for: url)
    }

    /// Returns cached `PodcastMetadata` for the given URL, or `nil` if not found.
    /// - Parameter url: RSS feed URL used as cache key.
    func cachedMetadata(for url: URL) -> PodcastMetadata? {
        guard let data = disk.read(for: url, suffix: Strings.Cache.metadataExtension) else { return nil }
        return try? JSONDecoder().decode(PodcastMetadata.self, from: data)
    }

    /// Writes `PodcastMetadata` to disk for the given URL.
    /// - Parameters:
    ///   - metadata: Podcast metadata to cache.
    ///   - url: RSS feed URL used as cache key.
    /// - Throws: `FileManager` error if the write fails.
    func cacheMetadata(_ metadata: PodcastMetadata, for url: URL) throws {
        try disk.write(JSONEncoder().encode(metadata), for: url, suffix: Strings.Cache.metadataExtension)
    }

    /// Removes the cached RSS data and metadata for the given URL.
    /// - Throws: `FileManager` error if the RSS data file cannot be removed.
    func invalidateCache(for url: URL) throws {
        try disk.remove(for: url)
        try? disk.remove(for: url, suffix: Strings.Cache.metadataExtension)
    }

    /// Removes all cached RSS data and recreates the empty cache directory.
    /// - Throws: `FileManager` error if removal or recreation fails.
    func clearCache() throws {
        try disk.clear()
    }

    /// Returns the total size in bytes of all files stored in the disk cache.
    func diskCacheSize() -> Int {
        disk.size()
    }
}
