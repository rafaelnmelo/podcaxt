import Foundation
import CryptoKit

/// Shared disk cache utility used by `ImageCache` and `RSSCache`.
/// Not thread-safe on its own — relies on the enclosing actor for serialization.
struct DiskCache {
    let diskURL: URL

    /// Creates the cache directory under the system caches folder.
    /// - Parameter directory: Subdirectory name inside the caches directory.
    init(directory: String) {
        diskURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns the cached `Data` for the given URL, or `nil` if not found.
    /// - Parameters:
    ///   - url: Remote URL used as cache key.
    ///   - suffix: Optional filename suffix (e.g. `.meta`).
    func read(for url: URL, suffix: String = "") -> Data? {
        try? Data(contentsOf: file(for: url, suffix: suffix))
    }

    /// Writes `Data` to disk for the given URL.
    /// - Parameters:
    ///   - data: Data to persist.
    ///   - url: Remote URL used as cache key.
    ///   - suffix: Optional filename suffix (e.g. `.meta`).
    func write(_ data: Data, for url: URL, suffix: String = "") throws {
        try data.write(to: file(for: url, suffix: suffix))
    }

    /// Removes the cached file for the given URL.
    /// - Parameters:
    ///   - url: Remote URL used as cache key.
    ///   - suffix: Optional filename suffix (e.g. `.meta`).
    func remove(for url: URL, suffix: String = "") throws {
        try FileManager.default.removeItem(at: file(for: url, suffix: suffix))
    }

    /// Removes all files in the cache directory and recreates it empty.
    func clear() throws {
        try FileManager.default.removeItem(at: diskURL)
        try FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns the total size in bytes of all files in the cache directory.
    func size() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: diskURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }

    /// Returns the file URL for the given remote URL and optional suffix.
    func file(for url: URL, suffix: String = "") -> URL {
        diskURL.appendingPathComponent(hash(for: url) + suffix)
    }

    /// Returns a SHA-256 hex string used as the disk filename for the given URL.
    private func hash(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}
