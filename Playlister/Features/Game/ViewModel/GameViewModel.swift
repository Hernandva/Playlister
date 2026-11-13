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

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: GameViewData

    private let provider: MusicProvider
    private let fetchSongsUseCase: any FetchGameSongsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameDependencies) {
        self.viewData = GameViewData(
            playlist: dependencies.resolvePlaylist(),
            settings: dependencies.resolveSettings()
        )
        self.provider = dependencies.resolveProvider()
        self.fetchSongsUseCase = dependencies.resolveFetchGameSongsUseCase()
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

    /// Reads every song of the playlist and shuffles them into the queue, so the game starts with a random one.
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
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
