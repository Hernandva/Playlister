import Foundation
import PlaylisterData

/// Display-ready data of ProviderStarter. The view model owns it and adds each use case result to its own field.
struct ProviderStarterViewData: Equatable, Sendable {
    /// Music service the user signed in with.
    enum Provider: Equatable, Sendable {
        case spotify
        case appleMusic

        init(_ musicProvider: MusicProvider) {
            switch musicProvider {
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

    /// A playlist shown in the selected playlist card. `Hashable` because the Game route carries it.
    struct Playlist: Hashable, Sendable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        /// `nil` when it was chosen in the selector, which does not read the songs.
        let songCount: Int?
        let covers: [URL]
    }

    /// Known before anything loads: it comes from Home.
    var provider: Provider
    /// Result of `LastPlaylistUseCase`. `nil` until it loads, or when no playlist has been played yet.
    var lastPlaylist: Playlist?
    /// Playlist chosen in the playlist selector. When there is one, it is shown and played instead of
    /// `lastPlaylist`, and Play saves it as the new last playlist.
    var selectedPlaylist: Playlist?
}
