import Foundation

/// Wire format of the Provider response. Internal to Networking: the app only sees ProviderResponseProtocol.
struct ProviderResponseDAO: Decodable, Sendable, ProviderResponseProtocol {}
