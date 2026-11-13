@testable import PlaylisterData
import Foundation
import Testing

/// The artist's countries: MusicBrainz's `country` first, Wikidata when MusicBrainz has none.
struct ArtistCountryTests {
    private struct Request: ArtistRequestProtocol {
        let artistName: String
        let isrc: String?
    }

    private struct Unavailable: Error {}

    /// Answers every search with `searchJSON`; there is no ISRC in these tests.
    private struct FakeMusicBrainz: MusicBrainzClientProtocol {
        let searchJSON: String

        func recording(isrc: String) async throws -> MusicBrainzISRCResponseDAO {
            throw Unavailable()
        }

        func searchArtists(named name: String) async throws -> MusicBrainzArtistSearchResponseDAO {
            try JSONDecoder().decode(MusicBrainzArtistSearchResponseDAO.self, from: Data(searchJSON.utf8))
        }
    }

    /// Answers with `codes`, or fails when `codes` is `nil`, and records the identifiers it was asked for.
    private actor FakeWikidata: WikidataClientProtocol {
        let codes: [String]?
        private(set) var askedIDs: [String] = []

        init(codes: [String]?) {
            self.codes = codes
        }

        func countries(musicBrainzID: String) async throws -> WikidataCountriesResponseDAO {
            askedIDs.append(musicBrainzID)
            guard let codes else { throw Unavailable() }
            return WikidataCountriesResponseDAO(results: .init(bindings: codes.map { .init(iso: .init(value: $0)) }))
        }
    }

    private static let senSenraID = "14e3ab81-da70-4cb7-b73e-c50aeee3fa46"

    /// An artist found by name whose `country` is `country` (no field at all when `nil`).
    private static func search(country: String?) -> String {
        let field = country.map { #", "country": "\#($0)""# } ?? ""
        return """
        {"artists": [{"id": "\(senSenraID)", "name": "Sen Senra", "type": "Person", "score": 100\(field)}]}
        """
    }

    private static func fetch(country: String?, wikidata: FakeWikidata) async throws -> any ArtistResponseProtocol {
        try await ArtistRepository(client: FakeMusicBrainz(searchJSON: search(country: country)), wikidata: wikidata)
            .fetchKind(Request(artistName: "Sen Senra", isrc: nil))
    }

    @Test func usesTheMusicBrainzCountryWithoutAskingWikidata() async throws {
        let wikidata = FakeWikidata(codes: ["FR"])

        let response = try await Self.fetch(country: "es", wikidata: wikidata)

        #expect(response.kind == .solo)
        #expect(response.countryCodes == ["ES"])
        #expect(await wikidata.askedIDs.isEmpty)
    }

    @Test func asksWikidataByMusicBrainzIDWhenThereIsNoCountry() async throws {
        let wikidata = FakeWikidata(codes: ["ES"])

        let response = try await Self.fetch(country: nil, wikidata: wikidata)

        #expect(response.countryCodes == ["ES"])
        #expect(await wikidata.askedIDs == [Self.senSenraID])
    }

    @Test func asksWikidataWhenTheMusicBrainzCountryHasNoFlag() async throws {
        let wikidata = FakeWikidata(codes: ["ES"])

        let response = try await Self.fetch(country: "XW", wikidata: wikidata)

        #expect(response.countryCodes == ["ES"])
    }

    @Test func keepsEveryCountryOfWikidataSortedAndOnce() async throws {
        let response = try await Self.fetch(country: nil, wikidata: FakeWikidata(codes: ["US", "PR", "US"]))

        #expect(response.countryCodes == ["PR", "US"])
    }

    @Test func aFailedWikidataKeepsTheKindWithoutCountries() async throws {
        let response = try await Self.fetch(country: nil, wikidata: FakeWikidata(codes: nil))

        #expect(response.kind == .solo)
        #expect(response.countryCodes.isEmpty)
    }

    @Test func buildsTheQueryOnlyFromAMusicBrainzID() {
        #expect(WikidataCountriesQueryDAO(musicBrainzID: Self.senSenraID)?.query.contains(Self.senSenraID) == true)
        #expect(WikidataCountriesQueryDAO(musicBrainzID: "\" } DELETE {") == nil)
    }

    @Test func pointsAtTheWikidataQueryService() throws {
        let url = try ArtistRepository.wikidataConfiguration.url(for: WikidataClient.sparqlService)
        #expect(url.absoluteString == "https://query.wikidata.org/sparql")
    }
}
