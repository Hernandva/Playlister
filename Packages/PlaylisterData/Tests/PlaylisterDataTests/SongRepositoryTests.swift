@testable import PlaylisterData
import Foundation
import Testing

private struct SongRequest: SongRequestProtocol {
    let provider: MusicProvider
    let playlistID: String
    let count: Int
}

private final class FakeSongService: SongServiceProtocol, @unchecked Sendable {
    let error: SongError?
    private(set) var receivedRequest: SongRequestDAO?

    init(error: SongError? = nil) {
        self.error = error
    }

    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO {
        receivedRequest = request
        if let error { throw error }
        let artwork = try #require(URL(string: "https://example.com/cover.jpg"))
        let song = SongItemDAO(id: "1", title: "Billie Jean", artistName: "Michael Jackson", artworkURL: artwork)
        return SongResponseDAO(provider: request.provider, items: [song])
    }
}

struct SongRepositoryTests {
    private static let request = SongRequest(provider: .appleMusic, playlistID: "p.123", count: 4)

    @Test func forwardsTheRequestToTheProviderService() async throws {
        let service = FakeSongService()
        let repository = SongRepository(services: [.appleMusic: service])

        let response = try await repository.fetchRandomSongs(Self.request)

        #expect(service.receivedRequest == SongRequestDAO(provider: .appleMusic, playlistID: "p.123", count: 4))
        #expect(response.songs.map(\.title) == ["Billie Jean"])
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let repository = SongRepository(services: [.appleMusic: FakeSongService(error: .playlistNotFound)])
        await #expect(throws: SongError.playlistNotFound) {
            try await repository.fetchRandomSongs(Self.request)
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = SongRepository(services: [:])
        await #expect(throws: SongError.unsupportedProvider(.spotify)) {
            try await repository.fetchRandomSongs(SongRequest(provider: .spotify, playlistID: "p.123", count: 4))
        }
    }
}

struct RandomSongPickerTests {
    @Test func picksCountDifferentSongs() {
        let picked = RandomSongPicker.pick(Array(1...10), count: 4)
        #expect(picked.count == 4)
        #expect(Set(picked).count == 4)
        #expect(Set(picked).isSubset(of: Set(1...10)))
    }

    @Test func picksEverySongOfAShortPlaylist() {
        #expect(Set(RandomSongPicker.pick([1, 2], count: 4)) == [1, 2])
    }
}
