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
                podcastInfo
                podcastDescription
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
                    duration: episode.duration?.formattedDuration
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedEpisode = episode }
            }
        } header: {
            episodesSectionHeader
        }
    }
}

// MARK: - Components

private extension PodcastDetailView {
    var podcastInfo: some View {
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
    }

    var podcastDescription: some View {
        Text(viewModel.podcast.description)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
    }

    var episodesSectionHeader: some View {
        Text("\(viewModel.podcast.episodes.count) Episodes")
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
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

#Preview {
    NavigationStack {
        PodcastDetailView(podcast: .mock)
    }
}
