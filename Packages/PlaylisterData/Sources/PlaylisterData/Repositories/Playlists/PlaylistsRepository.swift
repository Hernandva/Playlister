import Foundation

/// Public API of the Playlists repository. Features depend on this protocol, never on the concrete class.
public protocol PlaylistsRepositoryProtocol: Sendable {
    /// Reads the recommended playlists and the user's own playlists of the music service in `request`.
    /// Only the playlists themselves are read, never their songs. Throws `PlaylistsError`.
    func fetch(_ request: some PlaylistsRequestProtocol) async throws -> any PlaylistsResponseProtocol
}

/// Public entry point of the playlists: forwards each request to the service of its provider.
/// Flow: PlaylistsRequestProtocol -> PlaylistsRequestDAO -> provider service -> PlaylistsResponseDAO
/// -> PlaylistsResponseProtocol.
public final class PlaylistsRepository: PlaylistsRepositoryProtocol {
    /// How many playlists each call returns, and how far the catalogue search goes to find the recommended ones.
    static let limits = PlaylistsLimits(recommendations: 20, recommendationsSearch: 1000, library: 20)

    private let services: [MusicProvider: any PlaylistsServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicPlaylistsService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any PlaylistsServiceProtocol]) {
        self.services = services
    }

    public func fetch(_ request: some PlaylistsRequestProtocol) async throws -> any PlaylistsResponseProtocol {
        guard let service = services[request.provider] else {
            throw PlaylistsError.unsupportedProvider(request.provider)
        }
        return try await service.fetch(PlaylistsRequestDAO(request, limits: Self.limits))
    }
}
