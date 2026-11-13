import Foundation

/// Songs of a playlist. Internal to PlaylisterData: the app only sees SongResponseProtocol.
struct SongResponseDAO: Sendable, Equatable, SongResponseProtocol {
    let provider: MusicProvider
    let items: [SongItemDAO]

    var songs: [any SongItemProtocol] { items }
}

/// A song. Internal: the app only sees SongItemProtocol.
struct SongItemDAO: Sendable, Equatable, SongItemProtocol {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: URL
}

/// One page of the songs of a playlist. Internal: the app only sees PlaylistSongsResponseProtocol.
struct PlaylistSongsResponseDAO: Sendable, Equatable, PlaylistSongsResponseProtocol {
    let provider: MusicProvider
    let items: [PlaylistSongItemDAO]
    let total: Int?
    let hasMore: Bool

    var songs: [any PlaylistSongItemProtocol] { items }
}

/// A song as it is listed. Internal: the app only sees PlaylistSongItemProtocol.
struct PlaylistSongItemDAO: Sendable, Equatable, PlaylistSongItemProtocol {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: URL?
    let duration: TimeInterval?
    var catalogID: String?
    var albumName: String?
    var releaseYear: Int?
    var largeArtworkURL: URL?
}
