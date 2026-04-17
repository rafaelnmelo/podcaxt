import Foundation

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
    private let disk = DiskCache(directory: Strings.Cache.imageCacheDirectory)

    /// Sets the memory cache limit.
    private init() {
        memory.countLimit = 100
    }

    /// Returns cached image `Data` for the given URL, checking memory then disk.
    /// Promotes a disk hit into memory for subsequent accesses.
    /// - Parameter url: Remote URL used as cache key.
    func cachedData(for url: URL) -> Data? {
        let key = url.absoluteString as NSString
        if let data = memory.object(forKey: key) as Data? { return data }
        guard let data = disk.read(for: url) else { return nil }
        memory.setObject(data as NSData, forKey: key)
        return data
    }

    /// Stores image `Data` in both memory and disk cache.
    /// - Parameters:
    ///   - data: Raw image data to cache.
    ///   - url: Remote URL used as cache key.
    func cache(_ data: Data, for url: URL) {
        memory.setObject(data as NSData, forKey: url.absoluteString as NSString)
        try? disk.write(data, for: url)
    }

    /// Removes all images stored in memory. Disk cache remains intact.
    func clearMemoryCache() {
        memory.removeAllObjects()
    }

    /// Removes all images from disk and memory cache.
    func clearDiskCache() throws {
        try disk.clear()
        memory.removeAllObjects()
    }

    /// Returns the total size in bytes of all files stored in the disk cache.
    func diskCacheSize() -> Int {
        disk.size()
    }
}
