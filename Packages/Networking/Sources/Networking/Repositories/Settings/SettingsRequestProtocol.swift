import Foundation

/// Public data the app must provide to read the game settings through the Settings repository.
/// It has no fields: the settings are the same for every music service.
public protocol SettingsRequestProtocol: Sendable {}
