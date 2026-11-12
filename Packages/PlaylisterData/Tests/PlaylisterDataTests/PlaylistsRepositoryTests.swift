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
    private static let playlist = PlaylistsItemDAO(
        id: "pl.1",
        name: "Hitster España",
        songCount: 312,
        coverURLs: [URL(string: "https://example.com/cover.jpg")!]
    )

    @Test func forwardsTheRequestToTheProviderService() async throws {
        let response = PlaylistsResponseDAO(provider: .appleMusic, recommendedItems: [Self.playlist], libraryItems: [])
        let service = FakePlaylistsService(result: .success(response))
        let repository = PlaylistsRepository(services: [.appleMusic: service])

        let result = try await repository.fetch(PlaylistsRequest(provider: .appleMusic, recommendationsTerm: "Hitster"))

        #expect(service.receivedRequest == PlaylistsRequestDAO(provider: .appleMusic, recommendationsTerm: "Hitster"))
        #expect(result.provider == .appleMusic)
        #expect(result.recommended.map(\.name) == ["Hitster España"])
        #expect(result.recommended.first?.songCount == 312)
        #expect(result.library.isEmpty)
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let service = FakePlaylistsService(result: .failure(.notAuthorized))
        let repository = PlaylistsRepository(services: [.appleMusic: service])
        await #expect(throws: PlaylistsError.notAuthorized) {
            try await repository.fetch(PlaylistsRequest(provider: .appleMusic, recommendationsTerm: "Hitster"))
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = PlaylistsRepository(services: [:])
        await #expect(throws: PlaylistsError.unsupportedProvider(.spotify)) {
            try await repository.fetch(PlaylistsRequest(provider: .spotify, recommendationsTerm: "Hitster"))
        }
    }
}
