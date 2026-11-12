import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Reads the library through the Apple Music API (`AppleMusicAPIClient`), which gives web artwork, and the
/// recommended playlists by identifier and one page of a catalogue search through MusicKit. Each call is a single
/// request, and none reads the songs.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400

    private let client = AppleMusicAPIClient()

    /// `GET /v1/me/library/playlists`, in the order the API returns them.
    func fetchLibrary(_ request: LibraryPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        try checkAccess(for: request.provider)
        return try await mappingErrors {
            let page: AppleMusicPageDAO<AppleMusicLibraryPlaylistAttributesDAO> = try await client.get(
                "me/library/playlists",
                query: [URLQueryItem(name: "limit", value: "\(request.limit)")]
            )
            let items = page.data.compactMap { PlaylistsItemDAO(libraryPlaylist: $0, artworkSide: Self.artworkSide) }
            return PlaylistsResponseDAO(provider: .appleMusic, items: items)
        }
    }

    /// Reads every recommended playlist in one request, keeping the order of the ids. Playlists that are not in the
    /// catalogue (deleted or no longer shared) are left out without failing.
    func fetchRecommended(_ request: RecommendedPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        try checkAccess(for: request.provider)
        guard !request.playlistIDs.isEmpty else {
            return PlaylistsResponseDAO(provider: .appleMusic, items: [])
        }
        return try await mappingErrors {
            let itemIDs = request.playlistIDs.map { MusicItemID($0) }
            let catalogRequest = MusicCatalogResourceRequest<Playlist>(matching: \.id, memberOf: itemIDs)
            let found = try await catalogRequest.response().items
            let playlistsByID = [String: Playlist](found.map { ($0.id.rawValue, $0) }) { first, _ in first }
            let playlists = request.playlistIDs.compactMap { playlistsByID[$0] }
            return PlaylistsResponseDAO(provider: .appleMusic, items: playlists.map(Self.item(from:)))
        }
    }

    /// One page of the catalogue search, without top results. A full page means there may be more.
    func search(_ request: PlaylistsSearchRequestDAO) async throws -> PlaylistsSearchResponseDAO {
        try checkAccess(for: request.provider)
        let term = request.term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return PlaylistsSearchResponseDAO(provider: .appleMusic, items: [], hasMore: false)
        }
        return try await mappingErrors {
            var searchRequest = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
            searchRequest.limit = request.limit
            searchRequest.offset = request.offset
            searchRequest.includeTopResults = false
            let playlists = try await searchRequest.response().playlists
            return PlaylistsSearchResponseDAO(
                provider: .appleMusic,
                items: playlists.map(Self.item(from:)),
                hasMore: playlists.count >= request.limit
            )
        }
    }

    private func checkAccess(for provider: MusicProvider) throws {
        guard provider == .appleMusic else {
            throw PlaylistsError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw PlaylistsError.notAuthorized
        }
    }

    /// Turns every MusicKit failure into `PlaylistsError.unavailable`, but lets a cancellation through:
    /// the app cancels searches the user has already typed past.
    private func mappingErrors<Result: Sendable>(_ work: () async throws -> Result) async throws -> Result {
        do {
            return try await work()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PlaylistsError.unavailable
        }
    }

    private static func item(from playlist: Playlist) -> PlaylistsItemDAO {
        PlaylistsItemDAO(
            id: playlist.id.rawValue,
            name: playlist.name,
            curatorName: playlist.curatorName,
            artworkURL: webURL(of: playlist.artwork)
        )
    }

    /// Only web URLs are kept: `AsyncImage` cannot load a `musicKit://` artwork.
    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: artworkSide, height: artworkSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
