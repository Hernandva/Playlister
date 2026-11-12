import Foundation

/// Public data the app must provide to call the Playlists repository.
/// Declare here the fields the services need; PlaylistsRequestDAO turns them into the wire format.
public protocol PlaylistsRequestProtocol: Sendable {}
