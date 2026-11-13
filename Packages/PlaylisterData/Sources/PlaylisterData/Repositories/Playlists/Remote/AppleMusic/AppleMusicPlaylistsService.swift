import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Every call is one request to the Apple Music API through `AppleMusicAPIClient`, which gives web artwork, and none
/// reads the songs.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400

    private let client = AppleMusicAPIClient()

    /// `GET /v1/me/library/playlists`, in the order the API returns them.
    func fetchLibrary(_ request: LibraryPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        try checkAccess(for: request.provider)
        return try await mappingErrors {
            let page: AppleMusicPageDAO<AppleMusicPlaylistAttributesDAO> = try await client.get(
                "me/library/playlists",
                query: [URLQueryItem(name: "limit", value: "\(request.limit)")]
            )
            return PlaylistsResponseDAO(provider: request.provider, items: Self.items(from: page))
        }
    }

    /// `GET /v1/catalog/{storefront}/playlists?ids=…`: every recommended playlist in one request, in the order of the
    /// ids. Playlists that are not in the catalogue (deleted or no longer shared) are left out without failing.
    func fetchRecommended(_ request: RecommendedPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        try checkAccess(for: request.provider)
        guard !request.playlistIDs.isEmpty else {
            return PlaylistsResponseDAO(provider: request.provider, items: [])
        }
        return try await mappingErrors {
            let page: AppleMusicPageDAO<AppleMusicPlaylistAttributesDAO>
            do {
                page = try await client.get(
                    "catalog/\(try await client.storefront())/playlists",
                    query: [URLQueryItem(name: "ids", value: request.playlistIDs.joined(separator: ","))]
                )
            } catch let error as MusicDataRequest.Error where error.status == 404 {
                // None of the ids is in the catalogue.
                return PlaylistsResponseDAO(provider: request.provider, items: [])
            }
            let itemsByID = [String: PlaylistsItemDAO](Self.items(from: page).map { ($0.id, $0) }) { first, _ in first }
            return PlaylistsResponseDAO(
                provider: request.provider,
                items: request.playlistIDs.compactMap { itemsByID[$0] }
            )
        }
    }

    /// `GET /v1/catalog/{storefront}/search?types=playlists`: one page of the search. A next page is announced by the
    /// API's `next`.
    func search(_ request: PlaylistsSearchRequestDAO) async throws -> PlaylistsSearchResponseDAO {
        try checkAccess(for: request.provider)
        let term = request.term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return PlaylistsSearchResponseDAO(provider: request.provider, items: [], hasMore: false)
        }
        return try await mappingErrors {
            let response: AppleMusicPlaylistsSearchDAO = try await client.get(
                "catalog/\(try await client.storefront())/search",
                query: [
                    // The API expects the words of the term joined by «+».
                    URLQueryItem(name: "term", value: term.replacingOccurrences(of: " ", with: "+")),
                    URLQueryItem(name: "types", value: "playlists"),
                    URLQueryItem(name: "limit", value: "\(request.limit)"),
                    URLQueryItem(name: "offset", value: "\(request.offset)")
                ]
            )
            let page = response.results.playlists
            return PlaylistsSearchResponseDAO(
                provider: request.provider,
                items: page.map(Self.items(from:)) ?? [],
                hasMore: page?.next != nil
            )
        }
    }

    private func checkAccess(for provider: MusicProvider) throws {
        guard provider.usesAppleMusic else {
            throw PlaylistsError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw PlaylistsError.notAuthorized
        }
    }

    /// Turns every failure into `PlaylistsError.unavailable`, but lets a cancellation through:
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

    private static func items(from page: AppleMusicPageDAO<AppleMusicPlaylistAttributesDAO>) -> [PlaylistsItemDAO] {
        page.data.compactMap { PlaylistsItemDAO(playlist: $0, artworkSide: artworkSide) }
    }
}
