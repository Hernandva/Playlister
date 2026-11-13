import Foundation

/// Public data the app must provide to ask the Artist repository who sings a song.
public protocol ArtistRequestProtocol: Sendable {
    /// Artist of the song as the music service names it, e.g. «Queen» or «ROSALÍA».
    var artistName: String { get }
    /// International Standard Recording Code of the song, when the service gives it. With it the answer is exact:
    /// without it the artist is searched by name.
    var isrc: String? { get }
}
