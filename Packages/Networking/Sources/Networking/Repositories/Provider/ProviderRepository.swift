import Foundation

/// Public API of the Provider repository. Features depend on this protocol, never on the concrete class.
public protocol ProviderRepositoryProtocol: Sendable {
    /// Reads the data of the music service in `request`. Throws a `ProviderError` when it cannot be read.
    func fetch(_ request: some ProviderRequestProtocol) async throws -> any ProviderResponseProtocol
}

/// Data of a music service, read by the internal service of each provider. Internal: the app only sees
/// `ProviderRepositoryProtocol`.
protocol ProviderServiceProtocol: Sendable {
    func fetch(_ request: some ProviderRequestProtocol) async throws -> ProviderResponseDAO
}

/// Public entry point of the music services' data: forwards each request to the service of its provider.
public final class ProviderRepository: ProviderRepositoryProtocol {
    private let services: [MusicProvider: any ProviderServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicProviderService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any ProviderServiceProtocol]) {
        self.services = services
    }

    public func fetch(_ request: some ProviderRequestProtocol) async throws -> any ProviderResponseProtocol {
        guard let service = services[request.provider] else {
            throw ProviderError.unsupportedProvider(request.provider)
        }
        return try await service.fetch(request)
    }
}
