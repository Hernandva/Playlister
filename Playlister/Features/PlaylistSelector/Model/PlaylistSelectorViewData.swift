import Foundation
import PlaylisterData

/// Display-ready data of PlaylistSelector. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct PlaylistSelectorViewData: Equatable, Sendable {
    /// A playlist shown in a carousel and handed to GameStarter when the user selects it.
    /// Only what the music service returns for the playlist itself: its songs are read only by the long-press sheet.
    struct Playlist: Equatable, Sendable, Identifiable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        /// Who made the playlist, e.g. «Apple Music», when the service says so.
        let curatorName: String?
        /// The playlist's artwork: one URL, or none when it has no web artwork.
        let covers: [URL]
    }

    /// Result of `SearchByTermUseCase`: one page of a search.
    struct SearchPage: Equatable, Sendable {
        let playlists: [Playlist]
        /// Where the next page starts.
        let nextOffset: Int
        /// `true` when the next page may hold more playlists.
        let hasMore: Bool
    }

    /// Every page loaded so far for the current search term.
    struct SearchResults: Equatable, Sendable {
        let term: String
        var playlists: [Playlist] = []
        var nextOffset = 0
        var hasMore = false
    }

    /// A song of the long-press sheet.
    struct Song: Equatable, Sendable, Identifiable {
        let id: String
        let title: String
        let artist: String
        /// Album artwork, or `nil` when the song has none.
        let cover: URL?
        /// Length of the song, when the music service gives it.
        let duration: TimeInterval?
    }

    /// Result of `FetchSongsFromPlaylistUseCase`: one page of the songs of a playlist.
    struct SongsPage: Equatable, Sendable {
        let songs: [Song]
        /// Where the next page starts.
        let nextOffset: Int
        /// `true` when the next page may hold more songs.
        let hasMore: Bool
        /// Songs of the whole playlist, when the music service says so.
        let total: Int?
    }

    /// Every page of `FetchSongsFromPlaylistUseCase` loaded so far for the playlist of the long-press sheet.
    /// `PlaylistSongsViewModel`, the view model of that sheet, keeps it.
    struct PlaylistSongs: Equatable, Sendable {
        let playlistID: String
        var songs: [Song] = []
        var nextOffset = 0
        var hasMore = false
        var total: Int?
    }

    /// Brand name of the music service the user signed in with. Known before anything loads.
    var providerName: String
    /// Result of `HitsterPlayListUseCase`.
    var hitster: [Playlist] = []
    /// Result of `MyPlaylistUseCase`.
    var library: [Playlist] = []
    /// Pages of `SearchByTermUseCase` for the term in «Search playlists», or `nil` while it is empty.
    var search: SearchResults?
    /// Results of `PlaylistCustomArtworkUseCase`, by playlist identifier: covers of random songs for the
    /// playlists that have no artwork of their own.
    var customArtworks: [String: [URL]] = [:]

    init(provider: MusicProvider) {
        self.providerName = Self.displayName(of: provider)
    }

    /// Brand names are not translated.
    private static func displayName(of provider: MusicProvider) -> String {
        switch provider {
        case .spotify: "Spotify"
        case .appleMusic: "Apple Music"
        }
    }
}
