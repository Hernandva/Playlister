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
