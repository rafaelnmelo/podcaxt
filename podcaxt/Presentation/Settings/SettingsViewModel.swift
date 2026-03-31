import Foundation

enum CacheClearResult {
    case success
    case failure(String)
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var cacheSize: String = Strings.Settings.calculating
    @Published private(set) var isClearing = false
    @Published var showConfirmation = false
    @Published var clearResult: CacheClearResult?

    /// Fetches the combined disk cache size from image and RSS caches and updates `cacheSize`.
    func loadCacheSize() {
        Task {
            let imageSize = await ImageCache.shared.diskCacheSize()
            let rssSize = await RSSCache.shared.diskCacheSize()
            cacheSize = ByteCountFormatter.string(fromByteCount: Int64(imageSize + rssSize), countStyle: .file)
        }
    }

    /// Clears both image and RSS disk caches and updates `cacheSize`.
    func clearCache() {
        isClearing = true
        Task {
            do {
                try await ImageCache.shared.clearDiskCache()
                try await RSSCache.shared.clearCache()
                loadCacheSize()
                clearResult = .success
            } catch {
                clearResult = .failure(error.localizedDescription)
            }
            isClearing = false
        }
    }
}
