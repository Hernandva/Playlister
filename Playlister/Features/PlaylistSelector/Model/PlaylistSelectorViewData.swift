import Foundation
import PlaylisterData

/// Display-ready data of PlaylistSelector. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct PlaylistSelectorViewData: Equatable, Sendable {
    /// A playlist shown in a carousel and handed to ProviderStarter when the user selects it.
    struct Playlist: Equatable, Sendable, Identifiable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        let songCount: Int
        let covers: [URL]
    }

    /// Result of `PlaylistsUseCase`.
    struct Playlists: Equatable, Sendable {
        /// «Hitster» playlists of the catalogue.
        var recommended: [Playlist]
        /// Playlists in the user's library.
        var library: [Playlist]
    }

    /// Brand name of the music service the user signed in with. Known before anything loads.
    var providerName: String
    /// Result of `PlaylistsUseCase`, or `nil` until it loads.
    var playlists: Playlists?

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
