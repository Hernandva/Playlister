import Foundation

/// Public data the app must provide to play a song.
public protocol PlayerRequestProtocol: Sendable {
    /// Music service the song belongs to.
    var provider: MusicProvider { get }
    /// Identifier of the song in its music service, as the Song repository returned it.
    var songID: String { get }
    /// Second of the song where playback starts: 0 plays it from the beginning.
    var startTime: TimeInterval { get }
}
