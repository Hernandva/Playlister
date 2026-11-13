import Foundation

/// Public API of the Song repository. Features depend on this protocol, never on the concrete class.
public protocol SongRepositoryProtocol: Sendable {
    /// Up to `request.count` random songs of a playlist, among those with web artwork. Reads only the first page of
    /// the playlist's songs, in one request. Throws `SongError`.
    func fetchRandomSongs(_ request: some SongRequestProtocol) async throws -> any SongResponseProtocol
    /// One page of up to `SongRepository.songsPageSize` songs of a playlist, in their order, starting at
    /// `request.offset`. Throws `SongError`.
    func fetchSongs(_ request: some PlaylistSongsRequestProtocol) async throws -> any PlaylistSongsResponseProtocol
}

/// Public entry point of the songs: forwards each request to the service of its provider.
/// Flow: SongRequestProtocol -> SongRequestDAO -> provider service -> SongResponseDAO -> SongResponseProtocol.
public final class SongRepository: SongRepositoryProtocol {
    /// Songs per page of `fetchSongs(_:)`.
    static let songsPageSize = 25

    private let services: [MusicProvider: any SongServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicSongService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any SongServiceProtocol]) {
        self.services = services
    }

    public func fetchRandomSongs(_ request: some SongRequestProtocol) async throws -> any SongResponseProtocol {
        try await service(for: request.provider).fetchRandomSongs(SongRequestDAO(request))
    }

    public func fetchSongs(
        _ request: some PlaylistSongsRequestProtocol
    ) async throws -> any PlaylistSongsResponseProtocol {
        try await service(for: request.provider)
            .fetchSongs(PlaylistSongsRequestDAO(request, limit: Self.songsPageSize))
    }

    private func service(for provider: MusicProvider) throws -> any SongServiceProtocol {
        guard let service = services[provider] else {
            throw SongError.unsupportedProvider(provider)
        }
        return service
    }
}
