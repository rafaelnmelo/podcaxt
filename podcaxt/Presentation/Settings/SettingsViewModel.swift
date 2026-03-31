import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var cacheSize: String = Strings.Settings.calculating
    @Published private(set) var isClearing = false

    /// Fetches the combined disk cache size from image and RSS caches and updates `cacheSize`.
    func loadCacheSize() {
        Task {
            let imageSize = await ImageCache.shared.diskCacheSize()
            let rssSize = await RSSCache.shared.diskCacheSize()
            cacheSize = ByteCountFormatter.string(fromByteCount: Int64(imageSize + rssSize), countStyle: .file)
        }
    }

    /// Clears both image and RSS disk caches and resets `cacheSize` to zero.
    func clearCache() {
        isClearing = true
        Task {
            try? await ImageCache.shared.clearDiskCache()
            try? await RSSCache.shared.clearCache()
            cacheSize = ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
            isClearing = false
        }
    }
}
