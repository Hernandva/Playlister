import Foundation

/// Public data the app must provide to read random songs of a playlist.
public protocol SongRequestProtocol: Sendable {
    /// Music service the playlist belongs to.
    var provider: MusicProvider { get }
    /// Identifier of the playlist in its music service, as the Playlists repository returned it.
    var playlistID: String { get }
    /// Songs returned at most.
    var count: Int { get }
}

/// Public data the app must provide to read one page of the songs of a playlist, in their order.
public protocol PlaylistSongsRequestProtocol: Sendable {
    /// Music service the playlist belongs to.
    var provider: MusicProvider { get }
    /// Identifier of the playlist in its music service, as the Playlists repository returned it.
    var playlistID: String { get }
    /// Position of the first song of the page: 0 for the first page.
    var offset: Int { get }
}
