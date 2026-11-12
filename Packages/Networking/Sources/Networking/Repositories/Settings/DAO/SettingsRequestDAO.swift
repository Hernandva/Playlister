import Foundation

/// Wire format of the Settings request. Internal to Networking: never exposed to the app.
struct SettingsRequestDAO: Encodable, Sendable {
    init(_ request: some SettingsRequestProtocol) {
        // Copy the fields of the request protocol into encodable properties.
    }
}
