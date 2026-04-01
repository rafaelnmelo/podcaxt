import AVFoundation
import Combine

protocol AudioPlaying: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var currentEpisode: Episode? { get }
    var queue: [Episode] { get }

    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var durationPublisher: AnyPublisher<TimeInterval, Never> { get }
    var currentEpisodePublisher: AnyPublisher<Episode?, Never> { get }
    var errorPublisher: AnyPublisher<String, Never> { get }

    func load(queue: [Episode], startingAt episode: Episode)
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func nextEpisode()
    func previousEpisode()
}

final class AudioPlayerService: AudioPlaying {
    static let shared = AudioPlayerService()

    private let player = AVPlayer()
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentEpisode: Episode?
    @Published private(set) var queue: [Episode] = []

    private let errorSubject = PassthroughSubject<String, Never>()

    var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
    var durationPublisher: AnyPublisher<TimeInterval, Never> { $duration.eraseToAnyPublisher() }
    var currentEpisodePublisher: AnyPublisher<Episode?, Never> { $currentEpisode.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String, Never> { errorSubject.eraseToAnyPublisher() }

    private init() {
        setupAudioSession()
        observePlayerStatus()
        observePlayToEnd()
    }

    /// Loads a queue of episodes and starts playback from the given episode.
    /// - Parameters:
    ///   - queue: Full list of episodes to use as playback queue.
    ///   - episode: Episode to start playing immediately.
    func load(queue: [Episode], startingAt episode: Episode) {
        self.queue = queue
        play(episode: episode)
    }

    /// Resumes playback of the current episode.
    func play() {
        player.play()
        isPlaying = true
    }

    /// Pauses playback.
    func pause() {
        player.pause()
        isPlaying = false
    }

    /// Seeks to a specific time in the current episode.
    /// - Parameter time: Target playback position in seconds.
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }

    /// Advances to the next episode in the queue.
    /// Does nothing if the current episode is the last one.
    func nextEpisode() {
        guard
            let current = currentEpisode,
            let index = queue.firstIndex(of: current),
            index + 1 < queue.count
        else { return }
        play(episode: queue[index + 1])
    }

    /// Goes back to the previous episode in the queue.
    /// If current time is past 3 seconds, seeks to the beginning instead.
    /// Does nothing if the current episode is the first one.
    func previousEpisode() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard
            let current = currentEpisode,
            let index = queue.firstIndex(of: current),
            index - 1 >= 0
        else { return }
        play(episode: queue[index - 1])
    }
}

// MARK: - Private

private extension AudioPlayerService {
    func play(episode: Episode) {
        currentEpisode = episode
        let item = AVPlayerItem(url: episode.enclosureURL)
        player.replaceCurrentItem(with: item)
        observeDuration(for: item)
        play()
    }

    func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func observePlayerStatus() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    func observeDuration(for item: AVPlayerItem) {
        item.publisher(for: \.duration)
            .compactMap { $0.isNumeric ? $0.seconds : nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.duration = $0 }
            .store(in: &cancellables)

        item.publisher(for: \.status)
            .filter { $0 == .failed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let message = item.error?.localizedDescription ?? Strings.Player.streamError
                self?.isPlaying = false
                self?.errorSubject.send(message)
            }
            .store(in: &cancellables)
    }

    func observePlayToEnd() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.nextEpisode() }
            .store(in: &cancellables)
    }
}
