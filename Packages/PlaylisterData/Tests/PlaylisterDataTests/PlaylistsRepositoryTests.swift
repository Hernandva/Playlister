@testable import PlaylisterData
import Foundation
import Testing

private struct LibraryRequest: LibraryPlaylistsRequestProtocol {
    let provider: MusicProvider
}

private struct RecommendedRequest: RecommendedPlaylistsRequestProtocol {
    let provider: MusicProvider
    let playlistIDs: [String]
}

private struct SearchRequest: PlaylistsSearchRequestProtocol {
    let provider: MusicProvider
    let term: String
    let offset: Int
}

/// Records what it receives and answers with fixed results, or with `error` when there is one.
private final class FakePlaylistsService: PlaylistsServiceProtocol, @unchecked Sendable {
    let items: [PlaylistsItemDAO]
    let error: PlaylistsError?
    private(set) var libraryRequest: LibraryPlaylistsRequestDAO?
    private(set) var recommendedRequest: RecommendedPlaylistsRequestDAO?
    private(set) var searchRequest: PlaylistsSearchRequestDAO?

    init(items: [PlaylistsItemDAO] = [], error: PlaylistsError? = nil) {
        self.items = items
        self.error = error
    }

    func fetchLibrary(_ request: LibraryPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        libraryRequest = request
        if let error { throw error }
        return PlaylistsResponseDAO(provider: request.provider, items: items)
    }

    func fetchRecommended(_ request: RecommendedPlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        recommendedRequest = request
        if let error { throw error }
        return PlaylistsResponseDAO(provider: request.provider, items: items)
    }

    func search(_ request: PlaylistsSearchRequestDAO) async throws -> PlaylistsSearchResponseDAO {
        searchRequest = request
        if let error { throw error }
        return PlaylistsSearchResponseDAO(provider: request.provider, items: items, hasMore: true)
    }
}

struct PlaylistsRepositoryTests {
    private static let playlist = PlaylistsItemDAO(
        id: "pl.u-DdANxEPFj4Jyvq",
        name: "Hitster",
        curatorName: nil,
        artworkURL: URL(string: "https://example.com/cover.jpg")
    )

    @Test func readsTheLibraryWithItsLimit() async throws {
        let service = FakePlaylistsService(items: [Self.playlist])
        let repository = PlaylistsRepository(services: [.appleMusic: service])

        let response = try await repository.fetchLibrary(LibraryRequest(provider: .appleMusic))

        #expect(service.libraryRequest == LibraryPlaylistsRequestDAO(provider: .appleMusic, limit: 20))
        #expect(response.playlists.map(\.name) == ["Hitster"])
    }

    @Test func readsTheRecommendedPlaylistsByID() async throws {
        let service = FakePlaylistsService(items: [Self.playlist])
        let repository = PlaylistsRepository(services: [.appleMusic: service])
        let ids = ["pl.u-DdANxEPFj4Jyvq"]

        let request = RecommendedRequest(provider: .appleMusic, playlistIDs: ids)
        let response = try await repository.fetchRecommended(request)

        #expect(service.recommendedRequest == RecommendedPlaylistsRequestDAO(provider: .appleMusic, playlistIDs: ids))
        #expect(response.playlists.map(\.id) == ids)
    }

    @Test func searchesOnePageWithItsSize() async throws {
        let service = FakePlaylistsService(items: [Self.playlist])
        let repository = PlaylistsRepository(services: [.appleMusic: service])

        let response = try await repository.search(SearchRequest(provider: .appleMusic, term: "rock", offset: 25))

        let expected = PlaylistsSearchRequestDAO(provider: .appleMusic, term: "rock", offset: 25, limit: 25)
        #expect(service.searchRequest == expected)
        #expect(response.hasMore)
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let repository = PlaylistsRepository(services: [.appleMusic: FakePlaylistsService(error: .notAuthorized)])
        await #expect(throws: PlaylistsError.notAuthorized) {
            try await repository.fetchLibrary(LibraryRequest(provider: .appleMusic))
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = PlaylistsRepository(services: [:])
        await #expect(throws: PlaylistsError.unsupportedProvider(.spotify)) {
            try await repository.search(SearchRequest(provider: .spotify, term: "rock", offset: 0))
        }
    }
}
