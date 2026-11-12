import Foundation

public enum PlaylistsError: Error, Equatable, Sendable {
    /// There is no playlists service for this provider yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not given the app access to the music service.
    case notAuthorized
    /// The music service could not be reached or returned an error.
    case unavailable
}

/// A playlist of a music service, as the selector shows it.
public protocol PlaylistsItemProtocol: Sendable {
    /// Identifier of the playlist in its music service.
    var id: String { get }
    var name: String { get }
    /// Number of songs in the playlist.
    var songCount: Int { get }
    /// Up to four album covers of the playlist's songs, from different albums.
    var coverURLs: [URL] { get }
}

/// Public data the Playlists repository returns to the app.
public protocol PlaylistsResponseProtocol: Sendable {
    /// Music service the playlists belong to.
    var provider: MusicProvider { get }
    /// Playlists of the catalogue found with the request's `recommendationsTerm`.
    var recommended: [any PlaylistsItemProtocol] { get }
    /// Playlists in the user's library.
    var library: [any PlaylistsItemProtocol] { get }
}
