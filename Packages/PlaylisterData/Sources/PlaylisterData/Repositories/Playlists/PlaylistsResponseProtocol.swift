import Foundation

public enum PlaylistsError: Error, Equatable, Sendable {
    /// There is no playlists service for this provider yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not given the app access to the music service.
    case notAuthorized
    /// The music service could not be reached or returned an error.
    case unavailable
}

/// A playlist of a music service, with only what the service returns for the playlist itself.
public protocol PlaylistsItemProtocol: Sendable {
    /// Identifier of the playlist in its music service.
    var id: String { get }
    var name: String { get }
    /// Who made the playlist (e.g. «Apple Music»), when the service says so.
    var curatorName: String? { get }
    /// The playlist's own artwork, when it has one that can be loaded from the web.
    var artworkURL: URL? { get }
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
