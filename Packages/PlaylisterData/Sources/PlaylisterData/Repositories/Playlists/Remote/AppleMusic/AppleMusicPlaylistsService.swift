import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Wraps MusicKit: reads the recommended playlists by identifier and the library, and never reads the songs.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
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
            async let recommended = recommendedPlaylists(ids: request.recommendedPlaylistIDs)
            async let library = libraryPlaylists(limit: request.libraryLimit)
            return try await PlaylistsResponseDAO(
                provider: .appleMusic,
                recommendedItems: recommended.map(Self.item(from:)),
                libraryItems: library.map(Self.item(from:))
            )
        } catch {
            throw PlaylistsError.unavailable
        }
    }

    /// Reads every recommended playlist in one request, keeping the order of `ids`. Playlists that are not in the
    /// catalogue (deleted or no longer shared) are left out without failing.
    private func recommendedPlaylists(ids: [String]) async throws -> [Playlist] {
        guard !ids.isEmpty else { return [] }
        let itemIDs = ids.map { MusicItemID($0) }
        let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, memberOf: itemIDs)
        let found = try await request.response().items
        let playlistsByID = [String: Playlist](found.map { ($0.id.rawValue, $0) }) { first, _ in first }
        let playlists = ids.compactMap { playlistsByID[$0] }
        #if DEBUG
        let missing = ids.filter { playlistsByID[$0] == nil }
        debugPrint("[Playlists] recommended: 1 request, \(ids.count) ids, \(playlists.count) found, "
            + "missing: \(missing.isEmpty ? "none" : missing.joined(separator: ", "))")
        #endif
        return playlists
    }

    private func libraryPlaylists(limit: Int) async throws -> [Playlist] {
        var request = MusicLibraryRequest<Playlist>()
        request.limit = limit
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
