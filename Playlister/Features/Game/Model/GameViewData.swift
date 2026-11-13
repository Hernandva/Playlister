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

    /// The song that started playing, returned by `PlayGameSongUseCase`.
    struct Round: Equatable, Sendable {
        /// Second of the song where playback started: 0, or a random point for a clip.
        let startTime: TimeInterval
        /// Length of the whole song, from the player or else from the playlist, when it is known.
        let songDuration: TimeInterval?
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

    /// A song of the playlist, returned by `FetchGameSongsUseCase`.
    struct Song: Equatable, Sendable, Identifiable {
        /// Identifier of the song in its music service.
        let id: String
        let title: String
        let artist: String
        /// Album artwork, or `nil` when the song has none.
        let cover: URL?
        /// Length of the song, when the service gives it.
        let duration: TimeInterval?
        /// Identifier of the song in the service's catalogue, `nil` for songs the user uploaded.
        let catalogID: String?

        /// Identifier the player looks the song up with: the catalogue one when there is one, because a library id
        /// is only found when the song is in the device library.
        var playbackID: String {
            catalogID ?? id
        }
    }

    /// Known before anything loads: it comes from ProviderStarter.
    var playlist: Playlist
    /// Known before anything loads: it comes from ProviderStarter.
    var settings: Settings
    /// Songs of the playlist in the order the game plays them: shuffled once when the game starts.
    /// `nil` until they load.
    var queue: [Song]?
    /// Position in `queue` of the song that is playing.
    var currentIndex = 0
    /// Why the current song could not be played, already localised, or `nil` while it plays.
    var playbackError: String?
    /// The current song once it plays, or `nil` until then.
    var round: Round?
    /// Current time of the song in the player, in seconds of the whole song. Read by `GamePlaybackTimeUseCase`.
    var playbackTime: TimeInterval = 0
}
