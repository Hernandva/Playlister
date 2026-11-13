import Foundation

/// Public API of the Playlists repository. Features depend on this protocol, never on the concrete class.
/// Every call reads only the playlists themselves, never their songs, and throws `PlaylistsError`.
public protocol PlaylistsRepositoryProtocol: Sendable {
    /// The user's library playlists, most recently played first, up to `PlaylistsRepository.libraryLimit`.
    func fetchLibrary(
        _ request: some LibraryPlaylistsRequestProtocol
    ) async throws -> any PlaylistsResponseProtocol

    /// The catalogue playlists of `request.playlistIDs` that still exist, in the same order.
    func fetchRecommended(
        _ request: some RecommendedPlaylistsRequestProtocol
    ) async throws -> any PlaylistsResponseProtocol

    /// One page of up to `PlaylistsRepository.searchPageSize` catalogue playlists found with `request.term`,
    /// starting at `request.offset`.
    func search(
        _ request: some PlaylistsSearchRequestProtocol
    ) async throws -> any PlaylistsSearchResponseProtocol
}

/// Public entry point of the playlists: forwards each request to the service of its provider.
/// Flow: <Request>Protocol -> <Request>DAO -> provider service -> <Response>DAO -> <Response>Protocol.
public final class PlaylistsRepository: PlaylistsRepositoryProtocol {
    /// Library playlists returned at most, most recently played first.
    static let libraryLimit = 20
    /// Playlists per search page: the most MusicKit allows.
    static let searchPageSize = 25

    private let services: [MusicProvider: any PlaylistsServiceProtocol]

    public convenience init() {
        self.init(services: MusicProvider.appleMusicServices(AppleMusicPlaylistsService()))
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any PlaylistsServiceProtocol]) {
        self.services = services
    }

    public func fetchLibrary(
        _ request: some LibraryPlaylistsRequestProtocol
    ) async throws -> any PlaylistsResponseProtocol {
        try await service(for: request.provider)
            .fetchLibrary(LibraryPlaylistsRequestDAO(request, limit: Self.libraryLimit))
    }

    public func fetchRecommended(
        _ request: some RecommendedPlaylistsRequestProtocol
    ) async throws -> any PlaylistsResponseProtocol {
        try await service(for: request.provider).fetchRecommended(RecommendedPlaylistsRequestDAO(request))
    }

    public func search(
        _ request: some PlaylistsSearchRequestProtocol
    ) async throws -> any PlaylistsSearchResponseProtocol {
        try await service(for: request.provider).search(PlaylistsSearchRequestDAO(request, limit: Self.searchPageSize))
    }

    private func service(for provider: MusicProvider) throws -> any PlaylistsServiceProtocol {
        guard let service = services[provider] else {
            throw PlaylistsError.unsupportedProvider(provider)
        }
        return service
    }
}
