import Foundation

/// Public data the app must provide to call the Provider repository.
/// Declare here the fields the services need; ProviderRequestDAO turns them into the wire format.
public protocol ProviderRequestProtocol: Sendable {}
