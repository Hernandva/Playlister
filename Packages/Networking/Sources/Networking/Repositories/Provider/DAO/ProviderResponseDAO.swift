import Foundation

/// Data of a music service. Internal to Networking: the app only sees ProviderResponseProtocol.
struct ProviderResponseDAO: Sendable, ProviderResponseProtocol {
    let provider: MusicProvider
    let playlist: ProviderPlaylistDAO?

    var lastPlaylist: (any ProviderPlaylistProtocol)? { playlist }
}

/// Stored format of a playlist. Internal: the app only sees ProviderPlaylistProtocol.
struct ProviderPlaylistDAO: Codable, Sendable, Equatable, ProviderPlaylistProtocol {
    let id: String
    let name: String
    let songCount: Int
    let coverURLs: [URL]

    init(id: String, name: String, songCount: Int, coverURLs: [URL]) {
        self.id = id
        self.name = name
        self.songCount = songCount
        self.coverURLs = coverURLs
    }

    init(_ playlist: some ProviderPlaylistProtocol) {
        self.init(id: playlist.id, name: playlist.name, songCount: playlist.songCount, coverURLs: playlist.coverURLs)
    }
}
