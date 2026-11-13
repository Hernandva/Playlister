import Foundation

/// Query of `GET https://query.wikidata.org/sparql`: the ISO 3166-1 codes of the countries of the artist whose
/// MusicBrainz identifier (property P434) is given. A person's nationality is P27 (country of citizenship); a
/// group's, P495 (country of origin). Internal.
struct WikidataCountriesQueryDAO: Encodable, Sendable {
    let query: String
    let format = "json"

    /// `nil` when `musicBrainzID` is not a UUID, so nothing else can reach the query.
    init?(musicBrainzID: String) {
        guard let id = UUID(uuidString: musicBrainzID) else { return nil }
        let mbid = id.uuidString.lowercased()
        self.query = """
        SELECT DISTINCT ?iso WHERE { ?artist wdt:P434 "\(mbid)" . \
        ?artist wdt:P27|wdt:P495 ?country . ?country wdt:P297 ?iso . }
        """
    }
}

/// Answer of the query: one binding per country code. Internal.
struct WikidataCountriesResponseDAO: Decodable, Sendable {
    struct Results: Decodable, Sendable {
        let bindings: [Binding]
    }

    struct Binding: Decodable, Sendable {
        let iso: Value?
    }

    struct Value: Decodable, Sendable {
        let value: String
    }

    let results: Results

    /// The codes, sorted so the same artist always shows its flags in the same order.
    var countryCodes: [String] {
        ArtistCountryCode.valid(results.bindings.compactMap { $0.iso?.value }.sorted())
    }
}
