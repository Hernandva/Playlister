import Foundation

/// Public data the app must provide to read the user's library playlists.
public protocol LibraryPlaylistsRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
}

/// Public data the app must provide to read the recommended playlists.
public protocol RecommendedPlaylistsRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
    /// Identifiers, in the service's catalogue, of the playlists, in the order they are shown,
    /// e.g. `pl.u-DdANxEPFj4Jyvq`. Playlists that no longer exist or are no longer shared are left out.
    var playlistIDs: [String] { get }
}

/// Public data the app must provide to search the catalogue's playlists.
public protocol PlaylistsSearchRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
    /// Text the user typed. An empty term returns no playlists.
    var term: String { get }
    /// Position of the first playlist of the page: 0, then the `nextOffset` the app keeps.
    var offset: Int { get }
}
