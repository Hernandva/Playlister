@testable import PlaylisterData
import Foundation
import Testing

struct ArtistRepositoryTests {
    private struct Request: ArtistRequestProtocol {
        let artistName: String
        let isrc: String?
    }

    private struct NotFound: Error {}

    /// Answers from canned JSON and counts the calls.
    private actor FakeMusicBrainz: MusicBrainzClientProtocol {
        var recordingJSON: String?
        var searchJSON: String?
        private(set) var calls: [String] = []

        init(recordingJSON: String? = nil, searchJSON: String? = nil) {
            self.recordingJSON = recordingJSON
            self.searchJSON = searchJSON
        }

        func recording(isrc: String) async throws -> MusicBrainzISRCResponseDAO {
            calls.append("isrc:\(isrc)")
            guard let recordingJSON else { throw NotFound() }
            return try JSONDecoder().decode(MusicBrainzISRCResponseDAO.self, from: Data(recordingJSON.utf8))
        }

        func searchArtists(named name: String) async throws -> MusicBrainzArtistSearchResponseDAO {
            calls.append("name:\(name)")
            guard let searchJSON else { throw NotFound() }
            return try JSONDecoder().decode(MusicBrainzArtistSearchResponseDAO.self, from: Data(searchJSON.utf8))
        }
    }

    private static let queenRecording = """
    {"isrc": "GBUM71029604", "recordings": [{"id": "b1a9c0e9", "title": "Bohemian Rhapsody",
      "artist-credit": [{"name": "Queen", "joinphrase": "",
        "artist": {"id": "0383dadf", "name": "Queen", "type": "Group", "sort-name": "Queen"}}]}]}
    """

    @Test func readsTheKindByISRC() async throws {
        let musicBrainz = FakeMusicBrainz(recordingJSON: Self.queenRecording)
        let repository = ArtistRepository(client: musicBrainz)

        let response = try await repository.fetchKind(Request(artistName: "Queen", isrc: "gbum71029604"))

        #expect(response.kind == .group)
        #expect(response.artistName == "Queen")
        #expect(await musicBrainz.calls == ["isrc:GBUM71029604"])
    }

    @Test func searchesTheNameWhenTheISRCIsUnknown() async throws {
        let musicBrainz = FakeMusicBrainz(searchJSON: """
        {"artists": [{"id": "1", "name": "ROSALÍA", "type": "Person", "score": 100}]}
        """)
        let repository = ArtistRepository(client: musicBrainz)

        let response = try await repository.fetchKind(Request(artistName: "ROSALÍA", isrc: "ES5022100001"))

        #expect(response.kind == .solo)
        #expect(await musicBrainz.calls == ["isrc:ES5022100001", "name:ROSALÍA"])
    }

    /// A recording whose artist has no type in MusicBrainz.
    private static let untypedRecording = """
    {"isrc": "USRC17607839", "recordings": [{"id": "c2", "title": "Song",
      "artist-credit": [{"name": "Artist", "artist": {"id": "a1", "name": "Artist"}}]}]}
    """

    @Test func searchesTheNameWhenTheRecordingHasNoKind() async throws {
        let musicBrainz = FakeMusicBrainz(recordingJSON: Self.untypedRecording, searchJSON: """
        {"artists": [{"id": "a1", "name": "Artist", "type": "Person", "score": 100}]}
        """)
        let response = try await ArtistRepository(client: musicBrainz)
            .fetchKind(Request(artistName: "Artist", isrc: "USRC17607839"))

        #expect(response.kind == .solo)
        #expect(await musicBrainz.calls == ["isrc:USRC17607839", "name:Artist"])
    }

    @Test func keepsTheRecordingWhenTheSearchTellsNoMore() async throws {
        let weakSearch = FakeMusicBrainz(recordingJSON: Self.untypedRecording, searchJSON: """
        {"artists": [{"id": "x", "name": "Someone Else", "type": "Group", "score": 60}]}
        """)
        let failedSearch = FakeMusicBrainz(recordingJSON: Self.untypedRecording)

        for musicBrainz in [weakSearch, failedSearch] {
            let response = try await ArtistRepository(client: musicBrainz)
                .fetchKind(Request(artistName: "Artist", isrc: "USRC17607839"))
            #expect(response.kind == .unknown)
            #expect(response.artistName == "Artist")
        }
    }

    @Test func aWeakSearchMatchIsUnknown() async throws {
        let musicBrainz = FakeMusicBrainz(searchJSON: """
        {"artists": [{"id": "1", "name": "Someone Else", "type": "Group", "score": 60}]}
        """)
        let response = try await ArtistRepository(client: musicBrainz)
            .fetchKind(Request(artistName: "Nobody", isrc: nil))

        #expect(response.kind == .unknown)
        #expect(response.artistName == nil)
    }

    @Test func aFailedSearchThrowsUnavailable() async {
        let repository = ArtistRepository(client: FakeMusicBrainz())

        await #expect(throws: ArtistError.unavailable) {
            try await repository.fetchKind(Request(artistName: "Queen", isrc: nil))
        }
    }

    @Test func asksMusicBrainzOncePerArtist() async throws {
        let musicBrainz = FakeMusicBrainz(searchJSON: """
        {"artists": [{"id": "1", "name": "Rosalía", "type": "Person", "score": 100}]}
        """)
        let repository = ArtistRepository(client: musicBrainz)

        _ = try await repository.fetchKind(Request(artistName: "Rosalía", isrc: nil))
        let again = try await repository.fetchKind(Request(artistName: "ROSALIA", isrc: nil))

        #expect(again.kind == .solo)
        #expect(await musicBrainz.calls.count == 1)
    }

    @Test func mapsTheMusicBrainzTypes() {
        #expect(ArtistKind(musicBrainzType: "Person") == .solo)
        #expect(ArtistKind(musicBrainzType: "Group") == .group)
        #expect(ArtistKind(musicBrainzType: "Orchestra") == .group)
        #expect(ArtistKind(musicBrainzType: "Choir") == .group)
        #expect(ArtistKind(musicBrainzType: "Character") == .unknown)
        #expect(ArtistKind(musicBrainzType: nil) == .unknown)
    }

    @Test func escapesTheSearchPhrase() {
        let query = MusicBrainzArtistSearchQueryDAO(name: #"Guns "N" Roses"#)
        #expect(query.query == #"artist:"Guns \"N\" Roses""#)
    }

    @Test func declaresTheMusicBrainzServices() throws {
        let url = try ArtistRepository.configuration.url(for: MusicBrainzClient.isrcService)
        #expect(url.absoluteString == "https://musicbrainz.org/ws/2/isrc")
        #expect(MusicBrainzClient.userAgent.hasPrefix("Playlister/"))
    }
}
