import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Wraps MusicKit with two requests, the catalogue search and the library, and never reads the songs.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
    /// Recommended playlists read from the catalogue search (MusicKit allows up to 25).
    private static let recommendationsLimit = 20
    /// Library playlists read, most recently played first.
    private static let libraryLimit = 20
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400

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
                recommendedItems: recommended.map(Self.item(from:)),
                libraryItems: library.map(Self.item(from:))
            )
        } catch {
            throw PlaylistsError.unavailable
        }
    }

    private func recommendedPlaylists(term: String) async throws -> [Playlist] {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = Self.recommendationsLimit
        return try await Array(request.response().playlists)
    }

    private func libraryPlaylists() async throws -> [Playlist] {
        var request = MusicLibraryRequest<Playlist>()
        request.limit = Self.libraryLimit
        request.sort(by: \.lastPlayedDate, ascending: false)
        return try await Array(request.response().items)
    }

    private static func item(from playlist: Playlist) -> PlaylistsItemDAO {
        PlaylistsItemDAO(
            id: playlist.id.rawValue,
            name: playlist.name,
            curatorName: playlist.curatorName,
            artworkURL: webURL(of: playlist.artwork)
        )
    }

    /// Only web URLs are kept: library artwork can use a MusicKit scheme that `AsyncImage` cannot load.
    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: artworkSide, height: artworkSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
