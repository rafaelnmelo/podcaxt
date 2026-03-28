import SwiftUI

struct PodcastDetailView: View {
    @StateObject private var viewModel: PodcastDetailViewModel
    @StateObject private var imageLoader = ImageLoader()
    @State private var selectedEpisode: Episode?

    init(podcast: Podcast) {
        _viewModel = StateObject(wrappedValue: PodcastDetailViewModel(podcast: podcast))
    }

    var body: some View {
        List {
            headerSection
            episodesSection
        }
        .listStyle(.plain)
        .navigationTitle(viewModel.podcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.refresh() }
        .task { await imageLoader.load(from: viewModel.podcast.imageURL) }
        .navigationDestination(item: $selectedEpisode) { episode in
            Text(episode.title) // placeholder para PlayerView
        }
    }
}

// MARK: - Sections

private extension PodcastDetailView {
    var headerSection: some View {
        Section {
            VStack(alignment: .center, spacing: 16) {
                coverImage
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .center, spacing: 4) {
                    Text(viewModel.podcast.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(viewModel.podcast.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.podcast.category.name)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(viewModel.podcast.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowSeparator(.hidden)
    }

    var episodesSection: some View {
        Section {
            ForEach(viewModel.podcast.episodes) { episode in
                EpisodeRowView(
                    episode: episode,
                    duration: viewModel.formattedDuration(for: episode)
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedEpisode = episode }
            }
        } header: {
            Text("\(viewModel.podcast.episodes.count) Episodes")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    var coverImage: some View {
        if imageLoader.isLoading {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.2))
                .overlay(ProgressView())
        } else if let image = imageLoader.image {
            image.resizable().scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.2))
                .overlay(Image(systemName: "mic.fill").font(.largeTitle))
        }
    }
}

// MARK: - Episode Row

private struct EpisodeRowView: View {
    let episode: Episode
    let duration: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(episode.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Spacer()

                Image(systemName: "play.circle")
                    .foregroundStyle(.tint)
                    .font(.title2)
            }

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
                    Text("E")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 4)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            if !episode.description.isEmpty {
                Text(episode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PodcastDetailView(podcast: .mock)
    }
}
