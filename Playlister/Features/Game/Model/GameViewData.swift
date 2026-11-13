import Foundation

/// Display-ready data of Game. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct GameViewData: Equatable, Sendable {
    /// The playlist the game is played with, chosen in ProviderStarter.
    struct Playlist: Equatable, Sendable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        /// `nil` when it was chosen in the selector, which does not read the songs.
        let songCount: Int?
        let covers: [URL]
    }

    /// What each round plays of a song.
    enum Playback: Equatable, Sendable {
        case fullSong
        case clip
    }

    /// Where a clip starts in the song.
    enum ClipStart: Equatable, Sendable {
        case beginning
        case random
    }

    enum Mode: Equatable, Sendable {
        case classic
        case bingo
    }

    enum BingoLevel: Equatable, Sendable {
        case beginner
        case expert
    }

    /// The Bingo categories, by their color.
    enum BingoCategory: Hashable, Sendable {
        case pink
        case yellow
        case cyan
        case green
        case orange
    }

    /// The game settings the user saved in Settings, read when Play was tapped.
    struct Settings: Equatable, Sendable {
        var playback: Playback
        /// Length of a clip, in seconds.
        var clipSeconds: Int
        var clipStart: ClipStart
        var mode: Mode
        var bingoLevel: BingoLevel
        /// Bingo categories turned on for `bingoLevel`.
        var bingoCategories: Set<BingoCategory>
    }

    /// Data returned by `GameUseCase`. Rename it after what it holds and add one type and one field
    /// per use case, with the properties the view needs.
    struct Content: Equatable, Sendable {}

    /// Known before anything loads: it comes from ProviderStarter.
    var playlist: Playlist
    /// Known before anything loads: it comes from ProviderStarter.
    var settings: Settings
    /// Result of `GameUseCase`, or `nil` until it loads.
    var content: Content?
}
