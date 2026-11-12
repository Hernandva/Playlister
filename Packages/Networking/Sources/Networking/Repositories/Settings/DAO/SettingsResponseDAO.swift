import Foundation

/// Wire format of the Settings response. Internal to Networking: the app only sees SettingsResponseProtocol.
struct SettingsResponseDAO: Decodable, Sendable, SettingsResponseProtocol {}
