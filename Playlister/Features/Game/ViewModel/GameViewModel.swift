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

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: GameViewData

    private let provider: MusicProvider
    private let fetchSongsUseCase: any FetchGameSongsUseCaseProtocol
    private let playSongUseCase: any PlayGameSongUseCaseProtocol
    private let stopSongUseCase: any StopGameSongUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameDependencies) {
        self.viewData = GameViewData(
            playlist: dependencies.resolvePlaylist(),
            settings: dependencies.resolveSettings()
        )
        self.provider = dependencies.resolveProvider()
        self.fetchSongsUseCase = dependencies.resolveFetchGameSongsUseCase()
        self.playSongUseCase = dependencies.resolvePlayGameSongUseCase()
        self.stopSongUseCase = dependencies.resolveStopGameSongUseCase()
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

    /// Played share of the current song, 0…1. Not bound to playback yet.
    var progress: Double {
        0
    }

    /// Elapsed time of the current song. Not bound to playback yet.
    var elapsedText: String {
        Self.formatted(seconds: 0)
    }

    /// The song that is playing: the first of the shuffled queue when the game starts.
    var currentSong: GameViewData.Song? {
        guard let queue = viewData.queue, queue.indices.contains(viewData.currentIndex) else { return nil }
        return queue[viewData.currentIndex]
    }

    /// Length of a round: the clip length, or the length of the current song when it plays whole.
    var durationText: String {
        let settings = viewData.settings
        switch settings.playback {
        case .clip:
            return Self.formatted(seconds: settings.clipSeconds)
        case .fullSong:
            return Self.formatted(seconds: Int(currentSong?.duration ?? 0))
        }
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

    /// Stops the music when the user leaves the game.
    func stop() async {
        await stopSongUseCase.execute(provider: provider)
    }

    /// Plays the current song. When it cannot be played (missing or unavailable) it moves on to the next one, up to
    /// `maxSkippedSongs` in a row; errors of the account or the service stop and are shown, since every song would
    /// fail the same way.
    private func playCurrentSong() async {
        viewData.playbackError = nil
        var skipped = 0
        while let song = currentSong {
            do {
                try await playSongUseCase.execute(song: song, settings: viewData.settings, provider: provider)
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

    private static func message(for error: GamePlaybackError) -> String {
        switch error {
        case .subscriptionRequired: String(localized: "game.playback.subscriptionRequired")
        case .notAuthorized: String(localized: "game.playback.notAuthorized")
        case .unsupportedProvider: String(localized: "game.playback.unsupportedProvider")
        case .unavailable: String(localized: "game.playback.unavailable")
        }
    }
}
