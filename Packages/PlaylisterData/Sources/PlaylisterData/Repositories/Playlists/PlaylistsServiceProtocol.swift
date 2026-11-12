import Foundation

/// Playlists of one music service. Internal: every provider has its own service in `Remote/<Provider>/`,
/// registered in `PlaylistsRepository.init()`.
protocol PlaylistsServiceProtocol: Sendable {
    func fetchLibrary(_ request: LibraryPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO
    func fetchRecommended(_ request: RecommendedPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO
    func search(_ request: PlaylistsSearchRequestDAO) async throws -> PlaylistsSearchResponseDAO
}
