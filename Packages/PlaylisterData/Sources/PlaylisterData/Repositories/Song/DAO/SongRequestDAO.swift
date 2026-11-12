import Foundation

/// Wire format of the Song request. Internal to PlaylisterData: never exposed to the app.
struct SongRequestDAO: Encodable, Sendable {
    init(_ request: some SongRequestProtocol) {
        // Copy the fields of the request protocol into encodable properties.
    }
}
