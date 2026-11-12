import Foundation

/// Public data the app must provide to read the game settings through the Settings repository.
/// Each music service has its own settings.
public protocol SettingsRequestProtocol: Sendable {
    /// Music service the user signed in with.
    var provider: MusicProvider { get }
}
