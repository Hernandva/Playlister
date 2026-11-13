import Foundation

public enum ArtistError: Error, Equatable, Sendable {
    /// MusicBrainz could not be reached or returned an error.
    case unavailable
}

/// Whether a song is sung by one person or by a group.
public enum ArtistKind: Sendable, Equatable {
    /// One person: a solo artist.
    case solo
    /// A group, an orchestra or a choir.
    case group
    /// MusicBrainz does not know the artist, or does not say what it is.
    case unknown
}

/// Public data the Artist repository returns to the app.
public protocol ArtistResponseProtocol: Sendable {
    /// Main artist of the song as MusicBrainz names it, or `nil` when it was not found.
    var artistName: String? { get }
    var kind: ArtistKind { get }
}
