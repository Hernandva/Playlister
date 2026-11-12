import Foundation
import PlaylisterData

/// Display-ready data of PlaylistSelector. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct PlaylistSelectorViewData: Equatable, Sendable {
    /// A playlist shown in a carousel and handed to ProviderStarter when the user selects it.
    /// Only what the music service returns for the playlist itself: its songs are never read here.
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

    /// Brand name of the music service the user signed in with. Known before anything loads.
    var providerName: String
    /// Result of `HitsterPlayListUseCase`.
    var hitster: [Playlist] = []
    /// Result of `MyPlaylistUseCase`.
    var library: [Playlist] = []
    /// Pages of `SearchByTermUseCase` for the term in «Search playlists», or `nil` while it is empty.
    var search: SearchResults?

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
