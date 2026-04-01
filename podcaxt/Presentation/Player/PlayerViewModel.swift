import Foundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var currentEpisode: Episode?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var errorMessage: String?

    private let player: any AudioPlaying
    private var cancellables = Set<AnyCancellable>()

    init(player: any AudioPlaying = AudioPlayerService.shared) {
        self.player = player
        bindPlayer()
    }

    // MARK: - Public

    /// Loads a queue of episodes and starts playback from the given episode.
    /// - Parameters:
    ///   - queue: Full list of episodes to use as playback queue.
    ///   - episode: Episode to start playing immediately.
    func load(queue: [Episode], startingAt episode: Episode) {
        player.load(queue: queue, startingAt: episode)
    }

    /// Toggles between play and pause.
    func togglePlayPause() {
        isPlaying ? player.pause() : player.play()
    }

    /// Seeks to a specific time in the current episode.
    /// - Parameter time: Target playback position in seconds.
    func seek(to time: TimeInterval) {
        player.seek(to: time)
    }

    /// Advances to the next episode in the queue.
    func nextEpisode() {
        player.nextEpisode()
    }

    /// Goes back to the previous episode in the queue.
    func previousEpisode() {
        player.previousEpisode()
    }

    /// Returns the playback progress as a value between 0 and 1.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    /// Returns formatted current time string.
    var formattedCurrentTime: String {
        currentTime.formattedDuration ?? "0:00"
    }

    /// Returns formatted duration string.
    var formattedDuration: String {
        duration.formattedDuration ?? "0:00"
    }

    /// Returns whether there is a next episode available.
    var hasNextEpisode: Bool {
        guard let current = currentEpisode,
              let index = player.queue.firstIndex(of: current)
        else { return false }
        return index + 1 < player.queue.count
    }

    /// Returns whether there is a previous episode available.
    var hasPreviousEpisode: Bool {
        guard let current = currentEpisode,
              let index = player.queue.firstIndex(of: current)
        else { return false }
        return index > 0
    }
}

// MARK: - Private

private extension PlayerViewModel {
    func bindPlayer() {
        player.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        player.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTime)

        player.durationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)

        player.currentEpisodePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentEpisode)

        player.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.errorMessage = $0 }
            .store(in: &cancellables)
    }
}
