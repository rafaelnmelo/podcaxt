import SwiftUI

struct PodcastHistoryRowView: View {
    let feedURL: RSSFeedURL
    let viewModel: RSSInputViewModel

    @State private var title: String?
    @StateObject private var imageLoader = ImageLoader()

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = imageLoader.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title ?? feedURL.url.host() ?? feedURL.url.absoluteString)
                    .font(.body)
                    .lineLimit(1)
                Text(feedURL.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .task {
            guard let podcast = await viewModel.cachedPodcast(for: feedURL.url) else { return }
            title = podcast.title
            await imageLoader.load(from: podcast.imageURL)
        }
    }
}
