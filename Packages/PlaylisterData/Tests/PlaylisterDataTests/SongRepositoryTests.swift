@testable import PlaylisterData
import Foundation
import Testing

private struct SongRequest: SongRequestProtocol {
    let provider: MusicProvider
    let playlistID: String
    let count: Int
}

private struct PlaylistSongsRequest: PlaylistSongsRequestProtocol {
    let provider: MusicProvider
    let playlistID: String
    let offset: Int
}

private final class FakeSongService: SongServiceProtocol, @unchecked Sendable {
    let error: SongError?
    private(set) var receivedRequest: SongRequestDAO?
    private(set) var receivedPageRequest: PlaylistSongsRequestDAO?

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

    func fetchSongs(_ request: PlaylistSongsRequestDAO) async throws -> PlaylistSongsResponseDAO {
        receivedPageRequest = request
        if let error { throw error }
        let song = PlaylistSongItemDAO(
            id: "1", title: "La Bamba", artistName: "Ritchie Valens", artworkURL: nil, duration: 124
        )
        return PlaylistSongsResponseDAO(provider: request.provider, items: [song], total: 312, hasMore: true)
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

    @Test func asksForAPageOfTwentyFiveSongs() async throws {
        let service = FakeSongService()
        let repository = SongRepository(services: [.appleMusic: service])

        let response = try await repository.fetchSongs(
            PlaylistSongsRequest(provider: .appleMusic, playlistID: "pl.1", offset: 25)
        )

        #expect(service.receivedPageRequest == PlaylistSongsRequestDAO(
            provider: .appleMusic, playlistID: "pl.1", offset: 25, limit: 25
        ))
        #expect(response.songs.map(\.title) == ["La Bamba"])
        #expect(response.total == 312)
        #expect(response.hasMore)
    }

    @Test func rejectsAProviderWithoutServiceWhenListingSongs() async {
        let repository = SongRepository(services: [:])
        await #expect(throws: SongError.unsupportedProvider(.spotify)) {
            try await repository.fetchSongs(PlaylistSongsRequest(provider: .spotify, playlistID: "pl.1", offset: 0))
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
