import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @StateObject private var imageLoader = ImageLoader()
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                artwork
                title
                Spacer()
                playPauseButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            progressBar
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .onTapGesture { isExpanded = true }
        .sheet(isPresented: $isExpanded) {
            NavigationStack { PlayerView() }
        }
        .task(id: viewModel.currentEpisode?.id) {
            await imageLoader.load(from: viewModel.currentEpisode?.imageURL)
        }
    }

    private var artwork: some View {
        Group {
            if let image = imageLoader.image {
                image.resizable().scaledToFill()
            } else {
                Color.appImagePlaceholder
                    .overlay(Image(systemName: SystemImage.mic))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var title: some View {
        Text(viewModel.currentEpisode?.title ?? "")
            .font(.subheadline)
            .lineLimit(1)
    }

    private var playPauseButton: some View {
        Button(action: viewModel.togglePlayPause) {
            Image(systemName: viewModel.isPlaying ? SystemImage.pause : SystemImage.play)
                .font(.title3)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Capsule()
                .fill(.secondary.opacity(0.3))
                .frame(height: 3)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.6))
                        .frame(width: geo.size.width * viewModel.progress, height: 3)
                }
        }
        .frame(height: 3)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
