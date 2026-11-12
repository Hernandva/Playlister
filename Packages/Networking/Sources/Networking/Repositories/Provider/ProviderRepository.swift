import Foundation

/// Public API of the Provider repository. Features depend on this protocol, never on the concrete class.
public protocol ProviderRepositoryProtocol: Sendable {
    /// Calls one of the services in `ProviderRepository.configuration.serviceNames`.
    func fetch(
        _ request: some ProviderRequestProtocol,
        serviceName: String
    ) async throws -> any ProviderResponseProtocol
}

/// Talks to the Provider services.
/// Flow: ProviderRequestProtocol -> ProviderRequestDAO -> ProviderResponseDAO -> ProviderResponseProtocol.
public final class ProviderRepository: ProviderRepositoryProtocol {
    /// Fill in the base URL and the names of the services this repository consumes.
    public static let configuration = RepositoryConfiguration(
        baseURL: "",
        serviceNames: []
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    public init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = ProviderRepository.configuration
    ) {
        self.client = client
        self.configuration = configuration
    }

    public func fetch(
        _ request: some ProviderRequestProtocol,
        serviceName: String
    ) async throws -> any ProviderResponseProtocol {
        let url = try configuration.url(for: serviceName)
        let requestDAO = ProviderRequestDAO(request)
        let responseDAO: ProviderResponseDAO = try await client.request(url, method: .get, body: requestDAO)
        return responseDAO
    }
}
