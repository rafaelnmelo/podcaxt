import SwiftUI

struct PodcastDetailView: View {
    @StateObject private var viewModel: PodcastDetailViewModel
    @StateObject private var imageLoader = ImageLoader()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    init(podcast: Podcast) {
        _viewModel = StateObject(wrappedValue: PodcastDetailViewModel(podcast: podcast))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                heroHeader
                podcastInfo
                    .padding(16)
                episodesSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.refresh() }
        .task { await imageLoader.load(from: viewModel.podcast.imageURL) }
    }
}

// MARK: - Sections

private extension PodcastDetailView {
    var heroHeader: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .global).minY
            let isScrollingUp = offset > 0

            coverImage
                .frame(width: geo.size.width, height: 320 + (isScrollingUp ? offset : 0))
                .clipped()
                .offset(y: isScrollingUp ? -offset : 0)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
        }
        .frame(height: 320)
    }

    var episodesSection: some View {
        Section {
            ForEach(viewModel.podcast.episodes) { episode in
                EpisodeRowView(
                    episode: episode,
                    duration: episode.duration?.formattedDuration
                )
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    if playerViewModel.currentEpisode == episode {
                        playerViewModel.togglePlayPause()
                    } else {
                        playerViewModel.load(queue: viewModel.podcast.episodes, startingAt: episode)
                    }
                }
                Divider().padding(.leading, 16)
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
                .padding(.bottom, 8)

            Text(viewModel.podcast.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
    }

    var episodesSectionHeader: some View {
        Text(Strings.PodcastDetail.episodesHeader(viewModel.podcast.episodes.count))
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
    }

    @ViewBuilder
    var coverImage: some View {
        if imageLoader.isLoading {
            Color.appImagePlaceholder
                .overlay(ProgressView())
        } else if let image = imageLoader.image {
            image.resizable().scaledToFill()
        } else {
            Color.appImagePlaceholder
                .overlay(Image(systemName: SystemImage.mic).font(.system(size: 60)))
        }
    }
}

#Preview {
    NavigationStack {
        PodcastDetailView(podcast: .mock)
            .environmentObject(PlayerViewModel())
    }
}
