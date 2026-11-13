import Foundation
import Observation
import PlaylisterData

@MainActor
@Observable
final class GameViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// Songs in a row that cannot be played before the game gives up and shows the error.
    private static let maxSkippedSongs = 5
    /// How often the progress reads the player's time, in seconds: MusicKit does not announce it.
    /// The progress bar animates over the same time, so it grows without jumps.
    static let progressInterval: TimeInterval = 1

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: GameViewData

    private let provider: MusicProvider
    private let fetchSongsUseCase: any FetchGameSongsUseCaseProtocol
    private let playerUseCase: any GamePlayerUseCaseProtocol
    private let playBackStatusUseCase: any GamePlayBackStatusUseCaseProtocol
    /// `true` while a pause or a resume is on its way, so a second tap does not overlap it.
    @ObservationIgnored private var isTogglingPause = false
    /// Reads the player's time while a song plays.
    @ObservationIgnored private var progressTask: Task<Void, Never>?

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameDependencies) {
        self.viewData = GameViewData(
            playlist: dependencies.resolvePlaylist(),
            settings: dependencies.resolveSettings()
        )
        self.provider = dependencies.resolveProvider()
        self.fetchSongsUseCase = dependencies.resolveFetchGameSongsUseCase()
        self.playerUseCase = dependencies.resolveGamePlayerUseCase()
        self.playBackStatusUseCase = dependencies.resolveGamePlayBackStatusUseCase()
    }

    /// Summary of the settings for the chip at the top: «Clásico · 20 s», «Clásico · Canción entera»
    /// or «Bingo · Principiante».
    var modeSummary: String {
        let settings = viewData.settings
        switch settings.mode {
        case .classic:
            let playback = switch settings.playback {
            case .clip: String(localized: "game.mode.clip \(settings.clipSeconds)")
            case .fullSong: String(localized: "game.mode.fullSong")
            }
            return "\(String(localized: "settings.mode.classic")) · \(playback)"
        case .bingo:
            let level = switch settings.bingoLevel {
            case .beginner: String(localized: "settings.bingo.level.beginner")
            case .expert: String(localized: "settings.bingo.level.expert")
            }
            return "\(String(localized: "settings.mode.bingo")) · \(level)"
        }
    }

    /// Played share of the round, 0…1: of the clip, or of the whole song.
    var progress: Double {
        guard let length = roundLength, length > 0 else { return 0 }
        return elapsed / length
    }

    /// Time played since the round started.
    var elapsedText: String {
        Self.formatted(seconds: Int(elapsed))
    }

    /// The song that is playing: the first of the shuffled queue when the game starts.
    var currentSong: GameViewData.Song? {
        guard let queue = viewData.queue, queue.indices.contains(viewData.currentIndex) else { return nil }
        return queue[viewData.currentIndex]
    }

    /// Length of the round: the clip length, or the length of the song when it plays whole.
    var durationText: String {
        Self.formatted(seconds: Int(roundLength ?? 0))
    }

    /// Length of the round in seconds: the clip, or the whole song; `nil` while the song's length is unknown.
    private var roundLength: TimeInterval? {
        switch viewData.settings.playback {
        case .clip: TimeInterval(viewData.settings.clipSeconds)
        case .fullSong: viewData.round?.songDuration ?? currentSong?.duration
        }
    }

    /// Seconds played since the round started, from the player's time. 0 until the song sounds, and never past the
    /// round's length.
    private var elapsed: TimeInterval {
        guard let round = viewData.round else { return 0 }
        let played = max(0, viewData.playbackTime - round.startTime)
        guard let length = roundLength else { return played }
        return min(played, length)
    }

    private static func formatted(seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }

    /// Reads every song of the playlist, shuffles them into the queue and plays the first one.
    func load() async {
        state = .loading
        do {
            let songs = try await fetchSongsUseCase.execute(playlistID: viewData.playlist.id, provider: provider)
            guard !songs.isEmpty else {
                state = .failed(String(localized: "game.empty"))
                return
            }
            viewData.queue = songs.shuffled()
            viewData.currentIndex = 0
            state = .loaded
        } catch is CancellationError {
            state = .idle
            return
        } catch {
            state = .failed(error.localizedDescription)
            return
        }
        await playCurrentSong()
    }

    /// `false` until a song plays: there is nothing to pause yet.
    var canTogglePause: Bool {
        viewData.round != nil
    }

    /// Pauses the song, or plays it again from where it was paused. The progress stops while it is paused.
    func togglePause() async {
        guard canTogglePause, !isTogglingPause else { return }
        isTogglingPause = true
        defer { isTogglingPause = false }
        if viewData.isPaused {
            await resume()
        } else {
            await pause()
        }
    }

    private func pause() async {
        cancelProgress()
        viewData.isPaused = true
        await playerUseCase.pause(provider: provider)
        // The bar shows where the song stopped, not the last reading of the timer.
        viewData.playbackTime = await playBackStatusUseCase.execute(provider: provider).time
    }

    private func resume() async {
        do {
            try await playerUseCase.resume(provider: provider)
            viewData.isPaused = false
            viewData.playbackError = nil
            startProgress()
        } catch is CancellationError {
            return
        } catch {
            viewData.playbackError = Self.message(for: error as? GamePlaybackError ?? .unavailable)
        }
    }

    /// Stops the music when the user leaves the game.
    func stop() async {
        stopProgress()
        await playerUseCase.stop(provider: provider)
    }

    /// Plays the current song. When it cannot be played (missing or unavailable) it moves on to the next one, up to
    /// `maxSkippedSongs` in a row; errors of the account or the service stop and are shown, since every song would
    /// fail the same way.
    private func playCurrentSong() async {
        stopProgress()
        viewData.playbackError = nil
        var skipped = 0
        while let song = currentSong {
            do {
                viewData.round = try await playerUseCase.play(
                    song: song,
                    settings: viewData.settings,
                    provider: provider
                )
                startProgress()
                return
            } catch is CancellationError {
                return
            } catch GamePlaybackError.unavailable where skipped < Self.maxSkippedSongs {
                skipped += 1
                viewData.currentIndex += 1
            } catch {
                viewData.playbackError = Self.message(for: error as? GamePlaybackError ?? .unavailable)
                return
            }
        }
        viewData.playbackError = Self.message(for: .unavailable)
    }

    /// Reads the player's time and status every `progressInterval` until `stopProgress()`. When the song stops
    /// sounding on its own (a call, Control Center, the end of the song) the game pauses, so Play resumes it.
    private func startProgress() {
        progressTask = Task { [weak self] in
            // Until the song is heard once, a reading that is not playing is the player still starting.
            var hasPlayed = false
            while !Task.isCancelled {
                guard let self else { return }
                let reading = await playBackStatusUseCase.execute(provider: provider)
                guard !Task.isCancelled else { return }
                viewData.playbackTime = reading.time
                if reading.isPlaying {
                    hasPlayed = true
                } else if hasPlayed {
                    songDidStop()
                    return
                }
                try? await Task.sleep(for: .seconds(Self.progressInterval))
            }
        }
    }

    /// The song stopped without the user: the game shows it as paused and stops reading the player.
    private func songDidStop() {
        progressTask = nil
        viewData.isPaused = true
    }

    /// Stops reading the player's time and empties the round, so the bar starts again at 0.
    private func stopProgress() {
        cancelProgress()
        viewData.round = nil
        viewData.playbackTime = 0
        viewData.isPaused = false
    }

    /// Stops reading the player's time and keeps where the bar is.
    private func cancelProgress() {
        progressTask?.cancel()
        progressTask = nil
    }

    private static func message(for error: GamePlaybackError) -> String {
        switch error {
        case .subscriptionRequired: String(localized: "game.playback.subscriptionRequired")
        case .notAuthorized: String(localized: "game.playback.notAuthorized")
        case .unsupportedProvider: String(localized: "game.playback.unsupportedProvider")
        case .unavailable: String(localized: "game.playback.unavailable")
        }
    }
}
