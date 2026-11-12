import Foundation

public enum LastPlaylistError: Error, Equatable, Sendable {
    /// The playlist could not be written to the local storage.
    case storageFailed
}

/// A playlist of a music service, as the app stores and shows it.
public protocol LastPlaylistItemProtocol: Sendable {
    /// Identifier of the playlist in its music service.
    var id: String { get }
    var name: String { get }
    /// Number of songs in the playlist, or `nil` when it was chosen without reading its songs.
    var songCount: Int? { get }
    /// Up to four album covers of the playlist's songs, from different albums.
    var coverURLs: [URL] { get }
}

/// Public data the Provider repository returns to the app.
public protocol LastPlaylistResponseProtocol: Sendable {
    /// Music service the data belongs to.
    var provider: MusicProvider { get }
    /// The last playlist played with this music service, or `nil` when none has been chosen yet.
    var lastPlaylist: (any LastPlaylistItemProtocol)? { get }
}
