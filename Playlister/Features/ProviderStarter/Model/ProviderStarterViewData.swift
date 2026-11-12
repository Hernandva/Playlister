import Foundation
import Networking

/// Display-ready data of ProviderStarter, built from the Provider repository's public response protocol.
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

    /// The playlist played last, shown in the «Last playlist» card.
    struct Playlist: Equatable, Sendable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        let songCount: Int
        let covers: [URL]
    }

    let provider: Provider
    /// `nil` when the user has not chosen a playlist with this music service yet.
    let lastPlaylist: Playlist?

    init(response: any ProviderResponseProtocol) {
        self.provider = Provider(response.provider)
        self.lastPlaylist = response.lastPlaylist.map { playlist in
            Playlist(id: playlist.id, name: playlist.name, songCount: playlist.songCount, covers: playlist.coverURLs)
        }
    }
}
