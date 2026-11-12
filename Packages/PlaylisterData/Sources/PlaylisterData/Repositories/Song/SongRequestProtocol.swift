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
