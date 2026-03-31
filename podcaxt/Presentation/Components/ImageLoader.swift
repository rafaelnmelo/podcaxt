import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: Image?
    @Published private(set) var dominantColor: Color?
    @Published private(set) var isLoading = false

    private let imageService: any ImageFetching

    init(imageService: any ImageFetching = ImageService.shared) {
        self.imageService = imageService
    }

    func load(from url: URL?) async {
        image = nil
        dominantColor = nil
        guard let url else { return }
        isLoading = true
        defer { isLoading = false }
        guard let data = try? await imageService.fetchImage(from: url),
              let uiImage = UIImage(data: data) else { return }
        image = Image(uiImage: uiImage)
        dominantColor = uiImage.dominantColor
    }
}
