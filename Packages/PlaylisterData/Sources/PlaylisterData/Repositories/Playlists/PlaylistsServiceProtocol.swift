import Foundation

/// Playlists of one music service. Internal: every provider has its own service in `Remote/<Provider>/`,
/// registered in `PlaylistsRepository.init()`.
protocol PlaylistsServiceProtocol: Sendable {
    func fetch(_ request: PlaylistsRequestDAO) async throws -> PlaylistsResponseDAO
}
