import Foundation
import PlaylisterData

/// Texts of the Game screen built from the view model's data.
extension GameViewModel {
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

    /// Release year of the current song for the revealed card, or «—» when it is unknown.
    var revealedYear: String {
        currentSong?.releaseYear.map(String.init) ?? "—"
    }

    /// Length of the whole current song for the revealed card, when it is known.
    var revealedDurationText: String? {
        (viewData.round?.songDuration ?? currentSong?.duration).map { Self.formatted(seconds: Int($0)) }
    }

    /// Message shown under the controls when a song cannot be played.
    static func message(for error: GamePlaybackError) -> String {
        switch error {
        case .subscriptionRequired: String(localized: "game.playback.subscriptionRequired")
        case .notAuthorized: String(localized: "game.playback.notAuthorized")
        case .unsupportedProvider: String(localized: "game.playback.unsupportedProvider")
        case .unavailable: String(localized: "game.playback.unavailable")
        }
    }
}
