import SwiftUI

struct EpisodeRowView: View {
    let episode: Episode
    let duration: String?

    @EnvironmentObject private var playerViewModel: PlayerViewModel

    private var isPlaying: Bool { playerViewModel.isPlaying && playerViewModel.currentEpisode == episode }
    private var isActive: Bool { playerViewModel.currentEpisode == episode }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleRow
            metadataRow
            descriptionText
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Components

private extension EpisodeRowView {
    var titleRow: some View {
        HStack {
            Text(episode.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)

            Spacer()

            Image(systemName: isPlaying ? SystemImage.pauseCircle : SystemImage.playCircle)
                .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .font(.title2)
                .animation(.easeInOut(duration: 0.2), value: isPlaying)
        }
    }

    var metadataRow: some View {
        HStack(spacing: 8) {
            if let pubDate = episode.pubDate {
                Text(pubDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let duration {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if episode.isExplicit {
                explicitBadge
            }
        }
    }

    @ViewBuilder
    var descriptionText: some View {
        if !episode.description.isEmpty {
            Text(episode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    var explicitBadge: some View {
        Text("E")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 4)
            .background(Color.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    EpisodeRowView(episode: Episode.mocks[0], duration: Episode.mocks[0].duration?.formattedDuration)
        .padding()
        .environmentObject(PlayerViewModel())
}
