import Foundation

/// Public API of the Settings repository. Features depend on this protocol, never on the concrete class.
public protocol SettingsRepositoryProtocol: Sendable {
    /// Calls one of the services in `SettingsRepository.configuration.serviceNames`.
    func fetch(
        _ request: some SettingsRequestProtocol,
        serviceName: String
    ) async throws -> any SettingsResponseProtocol
}

/// Talks to the Settings services.
/// Flow: SettingsRequestProtocol -> SettingsRequestDAO -> SettingsResponseDAO -> SettingsResponseProtocol.
public final class SettingsRepository: SettingsRepositoryProtocol {
    /// Fill in the base URL and the names of the services this repository consumes.
    public static let configuration = RepositoryConfiguration(
        baseURL: "",
        serviceNames: []
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    public init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = SettingsRepository.configuration
    ) {
        self.client = client
        self.configuration = configuration
    }

    public func fetch(
        _ request: some SettingsRequestProtocol,
        serviceName: String
    ) async throws -> any SettingsResponseProtocol {
        let url = try configuration.url(for: serviceName)
        let requestDAO = SettingsRequestDAO(request)
        let responseDAO: SettingsResponseDAO = try await client.request(url, method: .get, body: requestDAO)
        return responseDAO
    }
}
