import Foundation

/// Public API of the Song repository. Features depend on this protocol, never on the concrete class.
public protocol SongRepositoryProtocol: Sendable {
    /// Up to `request.count` random songs of a playlist, among those with web artwork. Reads only the first page of
    /// the playlist's songs, in one request. Throws `SongError`.
    func fetchRandomSongs(_ request: some SongRequestProtocol) async throws -> any SongResponseProtocol
}

/// Public entry point of the songs: forwards each request to the service of its provider.
/// Flow: SongRequestProtocol -> SongRequestDAO -> provider service -> SongResponseDAO -> SongResponseProtocol.
public final class SongRepository: SongRepositoryProtocol {
    private let services: [MusicProvider: any SongServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicSongService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any SongServiceProtocol]) {
        self.services = services
    }

    public func fetchRandomSongs(_ request: some SongRequestProtocol) async throws -> any SongResponseProtocol {
        guard let service = services[request.provider] else {
            throw SongError.unsupportedProvider(request.provider)
        }
        return try await service.fetchRandomSongs(SongRequestDAO(request))
    }
}
