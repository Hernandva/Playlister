import Foundation

/// Public data the app must provide to read a music service through the Provider repository.
public protocol LastPlaylistRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
}
