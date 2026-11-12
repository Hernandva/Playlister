import Foundation

/// Public API of the Playlists repository. Features depend on this protocol, never on the concrete class.
public protocol PlaylistsRepositoryProtocol: Sendable {
    /// Calls one of the services in `PlaylistsRepository.configuration.serviceNames`.
    func fetch(
        _ request: some PlaylistsRequestProtocol,
        serviceName: String
    ) async throws -> any PlaylistsResponseProtocol
}

/// Talks to the Playlists services.
/// Flow: PlaylistsRequestProtocol -> PlaylistsRequestDAO -> PlaylistsResponseDAO -> PlaylistsResponseProtocol.
public final class PlaylistsRepository: PlaylistsRepositoryProtocol {
    /// Fill in the base URL and the names of the services this repository consumes.
    public static let configuration = RepositoryConfiguration(
        baseURL: "",
        serviceNames: []
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    public init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = PlaylistsRepository.configuration
    ) {
        self.client = client
        self.configuration = configuration
    }

    public func fetch(
        _ request: some PlaylistsRequestProtocol,
        serviceName: String
    ) async throws -> any PlaylistsResponseProtocol {
        let url = try configuration.url(for: serviceName)
        let requestDAO = PlaylistsRequestDAO(request)
        let responseDAO: PlaylistsResponseDAO = try await client.request(url, method: .get, body: requestDAO)
        return responseDAO
    }
}
