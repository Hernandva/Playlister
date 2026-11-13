import Foundation
import Observation

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

    private let useCase: any GameUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameDependencies) {
        self.viewData = GameViewData(
            playlist: dependencies.resolvePlaylist(),
            settings: dependencies.resolveSettings()
        )
        self.useCase = dependencies.resolveUseCase()
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

    /// Length of a round: the clip length, or «0:00» for a full song until its length is known.
    var durationText: String {
        let settings = viewData.settings
        return Self.formatted(seconds: settings.playback == .clip ? settings.clipSeconds : 0)
    }

    private static func formatted(seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }

    func load() async {
        state = .loading
        do {
            viewData.content = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
