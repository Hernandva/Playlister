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
    private struct Song: Equatable {
        let album: String?
        let artwork: String?
    }

    private static func pick(_ songs: [Song], count: Int) -> [Song] {
        RandomSongPicker.pick(songs, count: count, album: \.album, artworkURL: { $0.artwork.flatMap(URL.init) })
    }

    @Test func picksUpToCountSongs() {
        let songs = (1...10).map { Song(album: "Album \($0)", artwork: "https://example.com/\($0).jpg") }
        #expect(Self.pick(songs, count: 4).count == 4)
    }

    @Test func neverPicksSongsWithoutArtwork() {
        let songs = [Song(album: "A", artwork: nil), Song(album: "B", artwork: "https://example.com/b.jpg")]
        #expect(Self.pick(songs, count: 4) == [Song(album: "B", artwork: "https://example.com/b.jpg")])
    }

    @Test func picksOneSongPerAlbum() {
        let songs = (1...6).map { Song(album: "Same album", artwork: "https://example.com/\($0).jpg") }
        #expect(Self.pick(songs, count: 4).count == 1)
    }
}
