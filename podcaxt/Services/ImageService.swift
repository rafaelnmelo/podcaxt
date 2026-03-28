import Foundation

protocol ImageFetching {
    func fetchImage(from url: URL) async throws -> Data
}

final class ImageService: ImageFetching {
    static let shared = ImageService()

    private let cache: any ImageCaching

    init(cache: any ImageCaching = ImageCache.shared) {
        self.cache = cache
    }

    /// Returns image `Data` for the given URL.
    /// Lookup order: cache (memory → disk) → network.
    /// When fetched from network, result is automatically stored in cache.
    /// - Parameter url: Remote URL of the image.
    /// - Returns: Raw image `Data`.
    func fetchImage(from url: URL) async throws -> Data {
        if let cached = await cache.cachedData(for: url) {
            return cached
        }

        let (data, _) = try await URLSession.shared.debugData(from: url)
        await cache.cache(data, for: url)
        return data
    }
}
