import Foundation

/// Data read from a music service. Internal to Networking: the app only sees ProviderResponseProtocol.
struct ProviderResponseDAO: Sendable, ProviderResponseProtocol {
    let provider: MusicProvider
    let playlist: ProviderPlaylistDAO?

    var lastPlaylist: (any ProviderPlaylistProtocol)? { playlist }
}

/// A playlist read from a music service. Internal: the app only sees ProviderPlaylistProtocol.
struct ProviderPlaylistDAO: Sendable, Equatable, ProviderPlaylistProtocol {
    let name: String
    let songCount: Int
    let coverURLs: [URL]
}
