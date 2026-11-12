import Foundation

/// Wire format of the Playlists request. Internal to PlaylisterData: never exposed to the app.
struct PlaylistsRequestDAO: Encodable, Sendable {
    init(_ request: some PlaylistsRequestProtocol) {
        // Copy the fields of the request protocol into encodable properties.
    }
}
