import Foundation
import PlaylisterData

/// Display-ready data of Settings. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct SettingsViewData: Equatable, Sendable {
    /// Music service the user signed in with, shown in the Account section.
    enum Provider: Equatable, Sendable {
        case spotify
        case appleMusic

        init(_ provider: MusicProvider) {
            switch provider {
            case .spotify: self = .spotify
            case .appleMusic: self = .appleMusic
            }
        }

        /// Brand name of the service. Brand names are not translated.
        var displayName: String {
            switch self {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            }
        }
    }

    /// What each round plays of a song.
    enum Playback: Hashable, Sendable {
        case fullSong
        case clip
    }

    /// Where a clip starts in the song.
    enum ClipStart: Hashable, Sendable {
        case beginning
        case random
    }

    enum GameMode: Hashable, Sendable {
        case classic
        case bingo
    }

    /// Game settings, returned by `SettingsUseCase` and saved by `SaveSettingsUseCase`.
    struct Game: Equatable, Sendable {
        /// Lengths a clip can have, in seconds, and the step between them.
        static let clipSecondsRange = 5...60
        static let clipSecondsStep = 5

        var playback: Playback
        var clipSeconds: Int
        var clipStart: ClipStart
        var mode: GameMode
        /// Identifier of the Bingo level: the `id` of one of the `bingoLevels`.
        var bingoLevel: String
    }

    /// The five Bingo categories, by their color.
    enum BingoColor: Hashable, Sendable {
        case pink
        case yellow
        case cyan
        case green
        case orange
    }

    /// A category of a Bingo level: its color and its name in that level, already localised.
    struct BingoCategory: Equatable, Sendable, Identifiable {
        let color: BingoColor
        let title: String

        var id: BingoColor { color }
    }

    /// A Bingo level with its five categories, returned by `BingoLevelsUseCase`.
    struct BingoLevel: Equatable, Sendable, Identifiable {
        /// Identifier stored in the settings.
        let id: String
        let title: String
        let categories: [BingoCategory]
    }

    var provider: Provider
    /// Result of `SettingsUseCase`, or `nil` until it loads.
    var game: Game?
    /// Result of `BingoLevelsUseCase`, in the order Settings shows them. Empty until it loads.
    var bingoLevels: [BingoLevel] = []
}
