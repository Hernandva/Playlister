import Foundation

/// Wire format of the Provider request. Internal to Networking: never exposed to the app.
struct ProviderRequestDAO: Encodable, Sendable {
    init(_ request: some ProviderRequestProtocol) {
        // Copy the fields of the request protocol into encodable properties.
    }
}
