import Foundation

/// The Wikidata call the Artist repository makes. Internal, so tests can fake it.
protocol WikidataClientProtocol: Sendable {
    /// Countries of the artist whose MusicBrainz identifier is `musicBrainzID`.
    func countries(musicBrainzID: String) async throws -> WikidataCountriesResponseDAO
}

/// Asks the Wikidata Query Service (SPARQL) through `NetworkClient`, with the same `User-Agent` as MusicBrainz,
/// which Wikidata also asks of every client.
struct WikidataClient: WikidataClientProtocol {
    static let sparqlService = "sparql"

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    init(client: NetworkClient, configuration: RepositoryConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    func countries(musicBrainzID: String) async throws -> WikidataCountriesResponseDAO {
        guard let query = WikidataCountriesQueryDAO(musicBrainzID: musicBrainzID) else {
            return WikidataCountriesResponseDAO(results: .init(bindings: []))
        }
        return try await client.request(
            try configuration.url(for: Self.sparqlService),
            method: .get,
            body: query,
            headers: ["User-Agent": MusicBrainzClient.userAgent, "Accept": "application/sparql-results+json"]
        )
    }
}
