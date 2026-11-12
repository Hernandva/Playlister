import Foundation

public enum SongError: Error, Equatable, Sendable {
    /// There is no songs service for this provider yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not given the app access to the music service.
    case notAuthorized
    /// No playlist has the requested identifier.
    case playlistNotFound
    /// The music service could not be reached or returned an error.
    case unavailable
}

/// A song of a playlist.
public protocol SongItemProtocol: Sendable {
    /// Identifier of the song in its music service.
    var id: String { get }
    var title: String { get }
    var artistName: String { get }
    /// The song's album artwork, always a web URL.
    var artworkURL: URL { get }
}

/// Public data the Song repository returns to the app.
public protocol SongResponseProtocol: Sendable {
    /// Music service the songs belong to.
    var provider: MusicProvider { get }
    /// Random songs of the playlist; fewer than requested when it has fewer songs with web artwork.
    var songs: [any SongItemProtocol] { get }
}
