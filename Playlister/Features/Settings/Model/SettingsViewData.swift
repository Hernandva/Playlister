import Foundation
import PlaylisterData
import PlaylisterUI

/// Display-ready data of Settings. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct SettingsViewData: Equatable, Sendable {
    /// Music service the user signed in with, shown in the Account section.
    enum Provider: Equatable, Sendable {
        case spotify
        case appleMusic
        case free

        init(_ provider: MusicProvider) {
            switch provider {
            case .spotify: self = .spotify
            case .appleMusic: self = .appleMusic
            case .free: self = .free
            }
        }

        /// Name of the service. Brand names are not translated; free mode is.
        var displayName: String {
            switch self {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            case .free: String(localized: "provider.free")
            }
        }

        /// `true` when the player cannot change the Playback section: free mode always plays a fixed clip.
        var locksPlayback: Bool {
            self == .free
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
        /// Length of the clip in free mode, which always starts at a random point.
        static let freeClipSeconds = 30

        var playback: Playback
        var clipSeconds: Int
        var clipStart: ClipStart
        var mode: GameMode
        var bingoLevel: DSBingoLevel
        /// Bingo categories turned off, per level. A level that is missing has every category on.
        var disabledCategories: [DSBingoLevel: Set<DSBingoCategory>]

        /// The same settings with the playback of `provider`: free mode always plays
        /// `freeClipSeconds` from a random point; the other services keep what the player chose.
        func enforcingPlayback(of provider: Provider) -> Game {
            guard provider.locksPlayback else { return self }
            var game = self
            game.playback = .clip
            game.clipSeconds = Self.freeClipSeconds
            game.clipStart = .random
            return game
        }
    }

    var provider: Provider
    /// Result of `SettingsUseCase`, or `nil` until it loads.
    var game: Game?
}
