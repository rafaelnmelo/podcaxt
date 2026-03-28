import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: Image?
    @Published private(set) var isLoading: Bool = false

    private let imageService: any ImageFetching

    init(imageService: any ImageFetching = ImageService.shared) {
        self.imageService = imageService
    }

    /// Fetches and converts image data into a SwiftUI `Image`.
    /// - Parameter url: Remote URL of the image to load.
    func load(from url: URL) async {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? await imageService.fetchImage(from: url),
              let uiImage = UIImage(data: data) else { return }
        image = Image(uiImage: uiImage)
    }
}
