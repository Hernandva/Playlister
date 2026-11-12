import Foundation

public enum ProviderError: Error, Equatable, Sendable {
    /// There is no provider service for this music service yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not authorised Playlister to use the music service.
    case notAuthorized
    /// The music service could not be reached.
    case unavailable
}

/// A playlist of the music service, as the app may show it.
public protocol ProviderPlaylistProtocol: Sendable {
    var name: String { get }
    /// Number of songs in the playlist.
    var songCount: Int { get }
    /// Up to four album covers of the playlist's songs, from different albums.
    var coverURLs: [URL] { get }
}

/// Public data the Provider repository returns to the app.
public protocol ProviderResponseProtocol: Sendable {
    /// Music service the data comes from.
    var provider: MusicProvider { get }
    /// The playlist the user played last in the music service, or `nil` when there is none.
    var lastPlaylist: (any ProviderPlaylistProtocol)? { get }
}
