import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Wraps MusicKit: searches the catalogue for the recommended playlists and reads the user's library.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
    /// Recommended playlists read from the catalogue search (MusicKit allows up to 25).
    private static let recommendationsLimit = 12
    /// Library playlists read, most recently played first.
    private static let libraryLimit = 50

    func fetch(_ request: PlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        guard request.provider == .appleMusic else {
            throw PlaylistsError.unsupportedProvider(request.provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw PlaylistsError.notAuthorized
        }
        do {
            async let recommended = recommendedPlaylists(term: request.recommendationsTerm)
            async let library = libraryPlaylists()
            return try await PlaylistsResponseDAO(
                provider: .appleMusic,
                recommendedItems: recommended,
                libraryItems: library
            )
        } catch {
            throw PlaylistsError.unavailable
        }
    }

    private func recommendedPlaylists(term: String) async throws -> [PlaylistsItemDAO] {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = Self.recommendationsLimit
        let response = try await request.response()
        return try await AppleMusicPlaylistMapper.items(from: Array(response.playlists))
    }

    private func libraryPlaylists() async throws -> [PlaylistsItemDAO] {
        var request = MusicLibraryRequest<Playlist>()
        request.limit = Self.libraryLimit
        request.sort(by: \.lastPlayedDate, ascending: false)
        let response = try await request.response()
        return try await AppleMusicPlaylistMapper.items(from: Array(response.items))
    }
}
