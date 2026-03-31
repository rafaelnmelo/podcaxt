import Foundation
import CryptoKit

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

    private let diskURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Strings.Cache.rssCacheDirectory, isDirectory: true)
    }()

    /// Creates the disk cache directory if needed.
    init() {
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns cached RSS `Data` for the given URL, or `nil` if not found.
    /// - Parameter url: RSS feed URL used as cache key.
    func cachedData(for url: URL) -> Data? {
        try? Data(contentsOf: cacheFile(for: url))
    }

    /// Writes RSS `Data` to disk for the given URL.
    /// - Throws: `FileManager` error if the write fails.
    func cache(_ data: Data, for url: URL) throws {
        try data.write(to: cacheFile(for: url))
    }

    /// Returns cached `PodcastMetadata` for the given URL, or `nil` if not found.
    func cachedMetadata(for url: URL) -> PodcastMetadata? {
        guard let data = try? Data(contentsOf: metadataFile(for: url)) else { return nil }
        return try? JSONDecoder().decode(PodcastMetadata.self, from: data)
    }

    /// Writes `PodcastMetadata` to disk for the given URL.
    func cacheMetadata(_ metadata: PodcastMetadata, for url: URL) throws {
        try JSONEncoder().encode(metadata).write(to: metadataFile(for: url))
    }

    /// Removes the cached entry for a specific feed URL.
    /// - Throws: `FileManager` error if the file cannot be removed.
    func invalidateCache(for url: URL) throws {
        try FileManager.default.removeItem(at: cacheFile(for: url))
        try? FileManager.default.removeItem(at: metadataFile(for: url))
    }

    /// Removes all cached RSS feed data and recreates the empty cache directory.
    /// - Throws: `FileManager` error if removal or recreation of the directory fails.
    func clearCache() throws {
        try FileManager.default.removeItem(at: diskURL)
        try FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns the total size in bytes of all files stored in the disk cache.
    func diskCacheSize() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: diskURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { sum, url in
            sum + ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    /// Returns the file URL for the metadata file associated with the given feed URL.
    private func metadataFile(for url: URL) -> URL {
        diskURL.appendingPathComponent(hash(for: url) + Strings.Cache.metadataExtension)
    }

    /// Returns the file URL for the cached RSS data associated with the given feed URL.
    private func cacheFile(for url: URL) -> URL {
        return diskURL.appendingPathComponent(hash(for: url))
    }

    /// Returns a SHA-256 hex string used as the disk cache filename for the given URL.
    private func hash(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}
