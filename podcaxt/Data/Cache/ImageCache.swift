import Foundation
import CryptoKit

protocol ImageCaching: Actor {
    func cachedData(for url: URL) -> Data?
    func cache(_ data: Data, for url: URL)
    func clearMemoryCache()
    func clearDiskCache() throws
}

actor ImageCache: ImageCaching {
    static let shared = ImageCache()

    private let memory = NSCache<NSString, NSData>()
    private let diskURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
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

        if let cached = memory.object(forKey: key) as NSData?,
           let data = cached as Data? {
            return cached as Data
        }

        let filePath = diskURL.appendingPathComponent(cacheKey(for: url))
        if let data = try? Data(contentsOf: filePath) {
            memory.setObject(data as NSData, forKey: key)
            return data
        }

        return nil
    }

    /// Stores image `Data` in both memory and disk cache.
    /// - Parameters:
    ///   - data: Raw image data to cache.
    ///   - url: Remote URL used as cache key.
    func cache(_ data: Data, for url: URL) {
        let key = url.absoluteString as NSString
        memory.setObject(data as NSData, forKey: key)
        let filePath = diskURL.appendingPathComponent(cacheKey(for: url))
        do {
            try data.write(to: filePath)
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

    private func cacheKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}
