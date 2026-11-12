import Foundation

/// Public data the app must provide to call the Song repository.
/// Declare here the fields the services need; SongRequestDAO turns them into the wire format.
public protocol SongRequestProtocol: Sendable {}
