import Foundation

/// Public data the app must provide to call the Settings repository.
/// Declare here the fields the services need; SettingsRequestDAO turns them into the wire format.
public protocol SettingsRequestProtocol: Sendable {}
