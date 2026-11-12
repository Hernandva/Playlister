import Foundation
import MusicKit

/// Apple Music playlists. Internal: the app only sees `PlaylistsRepositoryProtocol`.
/// Wraps MusicKit: pages through the catalogue search and reads the library, and never reads the songs.
/// The limits come with the request, from `PlaylistsRepository.limits`.
struct AppleMusicPlaylistsService: PlaylistsServiceProtocol {
    /// Results per catalogue search page: the most MusicKit allows.
    private static let searchPageSize = 25
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
            async let recommended = recommendedPlaylists(term: request.recommendationsTerm, limits: request.limits)
            async let library = libraryPlaylists(limit: request.limits.library)
            return try await PlaylistsResponseDAO(
                provider: .appleMusic,
                recommendedItems: recommended.map(Self.item(from:)),
                libraryItems: library.map(Self.item(from:))
            )
        } catch {
            throw PlaylistsError.unavailable
        }
    }

    /// Reads search pages until there are enough playlists that contain the term, the search has been read as
    /// far as `limits.recommendationsSearch`, or a page comes back empty.
    /// Each page is its own request with an explicit `offset`: search results do not offer a next batch.
    /// Top results are left out, so every page holds only the search's own playlist results.
    private func recommendedPlaylists(term: String, limits: PlaylistsLimits) async throws -> [Playlist] {
        var collector = RecommendationsCollector<Playlist>(term: term, limits: limits) { $0.name }
        var requestCount = 0
        while !collector.isComplete {
            var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
            request.limit = Self.searchPageSize
            request.offset = requestCount * Self.searchPageSize
            request.includeTopResults = false
            let page = Array(try await request.response().playlists)
            requestCount += 1
            collector.add(page)
            logSearchPage(requestCount, page: page, collector: collector)
            if page.isEmpty { break }
        }
        #if DEBUG
        debugPrint("[Playlists] search «\(term)» done: \(requestCount) requests, "
            + "\(collector.readCount) results read, \(collector.items.count) matches")
        #endif
        return collector.items
    }

    /// Debug builds only: one line per search page with the requests made, the matches found so far and the names
    /// in the page, to see why they match or not.
    private func logSearchPage(_ requestCount: Int, page: [Playlist], collector: RecommendationsCollector<Playlist>) {
        #if DEBUG
        debugPrint("[Playlists] request \(requestCount): \(page.count) results, "
            + "\(collector.readCount) read, \(collector.items.count) matches")
        let names = page.map { $0.kind == .editorial ? "\($0.name) (editorial)" : $0.name }
        debugPrint("[Playlists] names: \(names.joined(separator: " | "))")
        #endif
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
