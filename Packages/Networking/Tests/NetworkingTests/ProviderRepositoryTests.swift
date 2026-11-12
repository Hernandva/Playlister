import Foundation
@testable import Networking
import Testing

private struct FakeProviderRequest: ProviderRequestProtocol {
    let provider: MusicProvider
}

private struct FakeProviderService: ProviderServiceProtocol {
    let result: Result<ProviderResponseDAO, ProviderError>

    func fetch(_ request: some ProviderRequestProtocol) async throws -> ProviderResponseDAO {
        try result.get()
    }
}

struct ProviderRepositoryTests {
    private static let playlist = ProviderPlaylistDAO(
        name: "Hitster España",
        songCount: 312,
        coverURLs: [URL(string: "https://example.com/cover.jpg")].compactMap { $0 }
    )

    @Test func returnsTheResponseOfTheProviderService() async throws {
        let response = ProviderResponseDAO(provider: .appleMusic, playlist: Self.playlist)
        let repository = ProviderRepository(services: [.appleMusic: FakeProviderService(result: .success(response))])

        let result = try await repository.fetch(FakeProviderRequest(provider: .appleMusic))

        #expect(result.provider == .appleMusic)
        #expect(result.lastPlaylist?.name == "Hitster España")
        #expect(result.lastPlaylist?.songCount == 312)
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let service = FakeProviderService(result: .failure(.notAuthorized))
        let repository = ProviderRepository(services: [.appleMusic: service])
        await #expect(throws: ProviderError.notAuthorized) {
            try await repository.fetch(FakeProviderRequest(provider: .appleMusic))
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = ProviderRepository(services: [:])
        await #expect(throws: ProviderError.unsupportedProvider(.spotify)) {
            try await repository.fetch(FakeProviderRequest(provider: .spotify))
        }
    }
}
