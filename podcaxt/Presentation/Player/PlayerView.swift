import SwiftUI

struct PlayerView: View {
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var imageLoader = ImageLoader()

    let episode: Episode
    let queue: [Episode]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            artwork
            episodeInfo
            progressSection
            controls
            Spacer()
        }
        .padding(.horizontal, 32)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.load(queue: queue, startingAt: episode)
            if let imageURL = episode.imageURL {
                await imageLoader.load(from: imageURL)
            }
        }
    }
}

// MARK: - Sections

private extension PlayerView {
    var artwork: some View {
        Group {
            if let image = imageLoader.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(Image(systemName: "mic.fill").font(.system(size: 60)))
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .scaleEffect(viewModel.isPlaying ? 1 : 0.9)
        .animation(.spring(duration: 0.3), value: viewModel.isPlaying)
    }

    var episodeInfo: some View {
        VStack(spacing: 6) {
            Text(viewModel.currentEpisode?.title ?? episode.title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(viewModel.currentEpisode?.author ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var progressSection: some View {
        VStack(spacing: 8) {
            Slider(value: Binding(
                get: { viewModel.progress },
                set: { viewModel.seek(to: $0 * viewModel.duration) }
            ))
            .tint(.primary)

            HStack {
                Text(viewModel.formattedCurrentTime)
                Spacer()
                Text(viewModel.formattedDuration)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    var controls: some View {
        HStack(spacing: 48) {
            previousButton
            playPauseButton
            nextButton
        }
    }
}

// MARK: - Components

private extension PlayerView {
    var playPauseButton: some View {
        Button(action: viewModel.togglePlayPause) {
            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.primary)
        }
    }

    var nextButton: some View {
        Button(action: viewModel.nextEpisode) {
            Image(systemName: "forward.fill")
                .font(.title)
                .foregroundStyle(viewModel.hasNextEpisode ? .primary : .tertiary)
        }
        .disabled(!viewModel.hasNextEpisode)
    }

    var previousButton: some View {
        Button(action: viewModel.previousEpisode) {
            Image(systemName: "backward.fill")
                .font(.title)
                .foregroundStyle(viewModel.hasPreviousEpisode ? .primary : .tertiary)
        }
        .disabled(!viewModel.hasPreviousEpisode)
    }
}

#Preview {
    NavigationStack {
        PlayerView(episode: Episode.mocks[0], queue: Episode.mocks)
    }
}
