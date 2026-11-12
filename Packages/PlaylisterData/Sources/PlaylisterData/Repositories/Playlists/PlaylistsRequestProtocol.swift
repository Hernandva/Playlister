import Foundation

/// Public data the app must provide to read the playlists of a music service.
public protocol PlaylistsRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
    /// Search term of the recommended playlists in the service's catalogue, e.g. «Hitster».
    var recommendationsTerm: String { get }
}
