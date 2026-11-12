@testable import PlaylisterData
import Foundation
import Testing

private struct PlaylistsRequest: PlaylistsRequestProtocol {
    let provider: MusicProvider
    let recommendationsTerm: String
}

private final class FakePlaylistsService: PlaylistsServiceProtocol, @unchecked Sendable {
    let result: Result<PlaylistsResponseDAO, PlaylistsError>
    private(set) var receivedRequest: PlaylistsRequestDAO?

    init(result: Result<PlaylistsResponseDAO, PlaylistsError>) {
        self.result = result
    }

    func fetch(_ request: PlaylistsRequestDAO) async throws -> PlaylistsResponseDAO {
        receivedRequest = request
        return try result.get()
    }
}

struct PlaylistsRepositoryTests {
    private static let request = PlaylistsRequest(provider: .appleMusic, recommendationsTerm: "Hitster")
    private static let playlist = PlaylistsItemDAO(
        id: "pl.1",
        name: "Hitster España",
        curatorName: "Apple Music",
        artworkURL: URL(string: "https://example.com/cover.jpg")
    )

    @Test func forwardsTheRequestToTheProviderService() async throws {
        let response = PlaylistsResponseDAO(provider: .appleMusic, recommendedItems: [Self.playlist], libraryItems: [])
        let service = FakePlaylistsService(result: .success(response))
        let repository = PlaylistsRepository(services: [.appleMusic: service])

        let result = try await repository.fetch(Self.request)

        let expected = PlaylistsRequestDAO(
            provider: .appleMusic,
            recommendationsTerm: "Hitster",
            limits: PlaylistsLimits(recommendations: 20, recommendationsSearch: 1000, library: 20)
        )
        #expect(service.receivedRequest == expected)
        #expect(result.provider == .appleMusic)
        #expect(result.recommended.map(\.name) == ["Hitster España"])
        #expect(result.recommended.first?.curatorName == "Apple Music")
        #expect(result.library.isEmpty)
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let service = FakePlaylistsService(result: .failure(.notAuthorized))
        let repository = PlaylistsRepository(services: [.appleMusic: service])
        await #expect(throws: PlaylistsError.notAuthorized) {
            try await repository.fetch(Self.request)
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = PlaylistsRepository(services: [:])
        await #expect(throws: PlaylistsError.unsupportedProvider(.spotify)) {
            try await repository.fetch(PlaylistsRequest(provider: .spotify, recommendationsTerm: "Hitster"))
        }
    }
}
