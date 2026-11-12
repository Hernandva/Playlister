import Foundation

public enum ProviderError: Error, Equatable, Sendable {
    /// The playlist could not be written to the local storage.
    case storageFailed
}

/// A playlist of a music service, as the app stores and shows it.
public protocol ProviderPlaylistProtocol: Sendable {
    /// Identifier of the playlist in its music service.
    var id: String { get }
    var name: String { get }
    /// Number of songs in the playlist.
    var songCount: Int { get }
    /// Up to four album covers of the playlist's songs, from different albums.
    var coverURLs: [URL] { get }
}

/// Public data the Provider repository returns to the app.
public protocol ProviderResponseProtocol: Sendable {
    /// Music service the data belongs to.
    var provider: MusicProvider { get }
    /// The last playlist played with this music service, or `nil` when none has been chosen yet.
    var lastPlaylist: (any ProviderPlaylistProtocol)? { get }
}
