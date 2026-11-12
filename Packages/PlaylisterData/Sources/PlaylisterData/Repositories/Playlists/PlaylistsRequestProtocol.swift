import Foundation

/// Public data the app must provide to read the playlists of a music service.
public protocol PlaylistsRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
    /// Identifiers, in the service's catalogue, of the recommended playlists, in the order they are shown,
    /// e.g. `pl.u-DdANxEPFj4Jyvq`. Playlists that no longer exist or are no longer shared are left out.
    var recommendedPlaylistIDs: [String] { get }
}
