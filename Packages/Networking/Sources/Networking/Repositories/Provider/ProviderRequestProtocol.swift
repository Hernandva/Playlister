import Foundation

/// Public data the app must provide to read a music service through the Provider repository.
public protocol ProviderRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
}
