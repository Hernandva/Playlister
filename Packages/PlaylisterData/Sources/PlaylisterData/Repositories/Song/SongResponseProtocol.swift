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

/// A song of a playlist as it is listed, with or without artwork.
public protocol PlaylistSongItemProtocol: Sendable {
    /// Identifier of the song in its music service.
    var id: String { get }
    var title: String { get }
    var artistName: String { get }
    /// The song's album artwork, a web URL, or `nil` when it has none.
    var artworkURL: URL? { get }
    /// Length of the song, when the service gives it.
    var duration: TimeInterval? { get }
}

/// One page of the songs of a playlist, in their order.
public protocol PlaylistSongsResponseProtocol: Sendable {
    /// Music service the songs belong to.
    var provider: MusicProvider { get }
    /// Up to `SongRepository.songsPageSize` songs.
    var songs: [any PlaylistSongItemProtocol] { get }
    /// Songs of the whole playlist, when the service says so.
    var total: Int? { get }
    /// `true` when the service announces a next page.
    var hasMore: Bool { get }
}
