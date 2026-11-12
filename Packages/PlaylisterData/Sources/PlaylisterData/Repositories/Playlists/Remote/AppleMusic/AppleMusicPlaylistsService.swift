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
    /// far as `limits.recommendationsSearch`, or there are no more results.
    private func recommendedPlaylists(term: String, limits: PlaylistsLimits) async throws -> [Playlist] {
        var collector = RecommendationsCollector<Playlist>(term: term, limits: limits) { $0.name }
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = Self.searchPageSize
        var page = try await request.response().playlists
        var requestCount = 1
        collector.add(Array(page))
        logSearchPage(requestCount, pageSize: page.count, collector: collector)
        while !collector.isComplete, page.hasNextBatch,
              let next = try await page.nextBatch(limit: Self.searchPageSize), !next.isEmpty {
            requestCount += 1
            collector.add(Array(next))
            logSearchPage(requestCount, pageSize: next.count, collector: collector)
            page = next
        }
        #if DEBUG
        debugPrint("[Playlists] search «\(term)» done: \(requestCount) requests, "
            + "\(collector.readCount) results read, \(collector.items.count) matches")
        #endif
        return collector.items
    }

    /// Debug builds only: one line per search page with the requests made and the matches found so far.
    private func logSearchPage(_ requestCount: Int, pageSize: Int, collector: RecommendationsCollector<Playlist>) {
        #if DEBUG
        debugPrint("[Playlists] request \(requestCount): \(pageSize) results, "
            + "\(collector.readCount) read, \(collector.items.count) matches")
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
