import Foundation

/// Data of a music service. Internal to PlaylisterData: the app only sees LastPlaylistResponseProtocol.
struct LastPlaylistResponseDAO: Sendable, LastPlaylistResponseProtocol {
    let provider: MusicProvider
    let playlist: LastPlaylistItemDAO?

    var lastPlaylist: (any LastPlaylistItemProtocol)? { playlist }
}

/// Stored format of a playlist. Internal: the app only sees LastPlaylistItemProtocol.
struct LastPlaylistItemDAO: Codable, Sendable, Equatable, LastPlaylistItemProtocol {
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

    init(_ playlist: some LastPlaylistItemProtocol) {
        self.init(id: playlist.id, name: playlist.name, songCount: playlist.songCount, coverURLs: playlist.coverURLs)
    }
}
