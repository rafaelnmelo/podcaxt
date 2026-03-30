import SwiftUI

struct PodcastHistoryRowView: View {
    let feedURL: RSSFeedURL
    let viewModel: RSSInputViewModel

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = viewModel.historyImages[feedURL.url] {
                    image.resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.historyTitles[feedURL.url] ?? feedURL.url.host() ?? feedURL.url.absoluteString)
                    .font(.body)
                    .lineLimit(1)
                Text(feedURL.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    PodcastHistoryRowView(feedURL: .mock, viewModel: RSSInputViewModel())
}
