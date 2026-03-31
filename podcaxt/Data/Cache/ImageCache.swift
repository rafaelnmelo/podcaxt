import Foundation
import CryptoKit

protocol ImageCaching: Actor {
    func cachedData(for url: URL) -> Data?
    func cache(_ data: Data, for url: URL)
    func clearMemoryCache()
    func clearDiskCache() throws
    func diskCacheSize() -> Int
}

actor ImageCache: ImageCaching {
    static let shared = ImageCache()

    private let memory = NSCache<NSString, NSData>()
    private let diskURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Strings.Cache.imageCacheDirectory, isDirectory: true)
    }()

    /// Sets the memory cache limit and creates the disk cache directory if needed.
    private init() {
        memory.countLimit = 100
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Returns cached image `Data` for the given URL, checking memory then disk.
    /// Returns `nil` if not found in either cache.
    /// - Parameter url: Remote URL used as cache key.
    func cachedData(for url: URL) -> Data? {
        let key = url.absoluteString as NSString
        if let data = memory.object(forKey: key) as Data? { return data }
        guard let data = try? Data(contentsOf: diskURL.appendingPathComponent(cacheKey(for: url))) else { return nil }
        memory.setObject(data as NSData, forKey: key)
        return data
    }

    /// Stores image `Data` in both memory and disk cache.
    /// - Parameters:
    ///   - data: Raw image data to cache.
    ///   - url: Remote URL used as cache key.
    func cache(_ data: Data, for url: URL) {
        let key = url.absoluteString as NSString
        memory.setObject(data as NSData, forKey: key)
        do {
            try data.write(to: diskURL.appendingPathComponent(cacheKey(for: url)))
        } catch {
            print("[ImageCache] failed to write to disk: \(error)")
        }
    }

    /// Removes all images stored in memory.
    /// Disk cache remains intact.
    func clearMemoryCache() {
        memory.removeAllObjects()
    }

    /// Removes all images stored on disk and in memory.
    /// Recreates the empty cache directory after clearing.
    /// - Throws: `FileManager` error if removal or recreation of the directory fails.
    func clearDiskCache() throws {
        try FileManager.default.removeItem(at: diskURL)
        try FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
        memory.removeAllObjects()
    }

    /// Returns the total size in bytes of all files stored in the disk cache.
    func diskCacheSize() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: diskURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { sum, url in
            sum + ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    /// Returns a SHA-256 hex string used as the disk cache filename for the given URL.
    private func cacheKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}
