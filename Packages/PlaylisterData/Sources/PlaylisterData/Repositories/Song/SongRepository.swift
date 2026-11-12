import Foundation

/// Public API of the Song repository. Features depend on this protocol, never on the concrete class.
public protocol SongRepositoryProtocol: Sendable {
    /// Calls one of the services in `SongRepository.configuration.serviceNames`.
    func fetch(
        _ request: some SongRequestProtocol,
        serviceName: String
    ) async throws -> any SongResponseProtocol
}

/// Talks to the Song services.
/// Flow: SongRequestProtocol -> SongRequestDAO -> SongResponseDAO -> SongResponseProtocol.
public final class SongRepository: SongRepositoryProtocol {
    /// Fill in the base URL and the names of the services this repository consumes.
    public static let configuration = RepositoryConfiguration(
        baseURL: "",
        serviceNames: []
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    public init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = SongRepository.configuration
    ) {
        self.client = client
        self.configuration = configuration
    }

    public func fetch(
        _ request: some SongRequestProtocol,
        serviceName: String
    ) async throws -> any SongResponseProtocol {
        let url = try configuration.url(for: serviceName)
        let requestDAO = SongRequestDAO(request)
        let responseDAO: SongResponseDAO = try await client.request(url, method: .get, body: requestDAO)
        return responseDAO
    }
}
