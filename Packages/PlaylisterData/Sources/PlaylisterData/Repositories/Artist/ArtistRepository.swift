import Foundation

/// Public API of the Artist repository. Features depend on this protocol, never on the concrete class.
public protocol ArtistRepositoryProtocol: Sendable {
    /// Whether the main artist of a song is a solo artist or a group, and its countries, from MusicBrainz: by the
    /// song's ISRC when it has one, and by searching the artist's name when there is none or the ISRC tells nothing.
    /// When MusicBrainz has no country for the artist (often it only knows a city), Wikidata is asked with the
    /// artist's MusicBrainz identifier. An artist MusicBrainz does not know is `.unknown`, not an error; a country
    /// nobody knows leaves `countryCodes` empty. Throws `ArtistError.unavailable`; a cancelled call rethrows
    /// `CancellationError`.
    func fetchKind(_ request: some ArtistRequestProtocol) async throws -> any ArtistResponseProtocol
}

/// Asks MusicBrainz what kind of artist sings a song and where it is from, and Wikidata for the country when
/// MusicBrainz does not have it.
/// Flow: ArtistRequestProtocol -> ArtistRequestDAO -> MusicBrainz -> MusicBrainz…DAO -> ArtistResponseDAO,
/// then, without a country, -> Wikidata -> WikidataCountriesResponseDAO -> ArtistResponseDAO.
/// Answers are kept in memory for the life of the repository, by ISRC and by artist name.
public final class ArtistRepository: ArtistRepositoryProtocol {
    /// MusicBrainz web service, version 2. `isrc` looks a recording up by its ISRC, `artist` searches artists.
    public static let configuration = RepositoryConfiguration(
        baseURL: "https://musicbrainz.org/ws/2",
        serviceNames: [MusicBrainzClient.isrcService, MusicBrainzClient.artistService]
    )
    /// Wikidata Query Service: `sparql` runs a query, here the countries of an artist by its MusicBrainz identifier.
    public static let wikidataConfiguration = RepositoryConfiguration(
        baseURL: "https://query.wikidata.org",
        serviceNames: [WikidataClient.sparqlService]
    )
    /// Lowest search score (0…100) for an artist found by name to count as the song's artist.
    static let minimumSearchScore = 90

    private let client: any MusicBrainzClientProtocol
    private let wikidata: (any WikidataClientProtocol)?
    private let cache = ArtistKindCache()

    public convenience init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = ArtistRepository.configuration,
        wikidataConfiguration: RepositoryConfiguration = ArtistRepository.wikidataConfiguration
    ) {
        self.init(
            client: MusicBrainzClient(client: client, configuration: configuration),
            wikidata: WikidataClient(client: client, configuration: wikidataConfiguration)
        )
    }

    /// Lets tests inject a fake MusicBrainz and a fake Wikidata. Without `wikidata`, only MusicBrainz's country is
    /// used.
    init(client: any MusicBrainzClientProtocol, wikidata: (any WikidataClientProtocol)? = nil) {
        self.client = client
        self.wikidata = wikidata
    }

    public func fetchKind(_ request: some ArtistRequestProtocol) async throws -> any ArtistResponseProtocol {
        let requestDAO = ArtistRequestDAO(request)
        if let cached = await cache.response(for: requestDAO) {
            return cached
        }
        let (response, isComplete) = try await withCountries(try await lookUp(requestDAO))
        // A Wikidata call that failed is asked again next time instead of keeping the artist without a country.
        if isComplete {
            await cache.store(response, for: requestDAO)
        }
        return response
    }

    /// Adds the artist's countries from Wikidata when MusicBrainz gave none. `isComplete` is `false` when Wikidata
    /// could not answer; a failure there never fails the call, which already knows the kind.
    private func withCountries(_ response: ArtistResponseDAO) async throws -> (ArtistResponseDAO, isComplete: Bool) {
        guard response.countryCodes.isEmpty, let id = response.musicBrainzID, let wikidata else {
            return (response, true)
        }
        do {
            let codes = try await wikidata.countries(musicBrainzID: id).countryCodes
            return (response.with(countryCodes: codes), true)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return (response, false)
        }
    }

    /// By ISRC first; when MusicBrainz does not know the recording (or the call fails), or knows it but not the kind
    /// of its artist, by the artist's name. When the name tells no more, the recording's answer is kept.
    private func lookUp(_ request: ArtistRequestDAO) async throws -> ArtistResponseDAO {
        guard let byISRC = try await recording(isrc: request.isrc) else {
            return try await search(request.artistName)
        }
        guard byISRC.kind == .unknown else {
            return byISRC
        }
        do {
            let byName = try await search(request.artistName)
            return byName.kind == .unknown ? byISRC : byName
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // The recording already answered: a failed search does not make it an error.
            return byISRC
        }
    }

    /// The main artist of the recording with `isrc`, or `nil` without an ISRC, when MusicBrainz does not know it
    /// (an unknown ISRC answers 404) or when the call fails.
    private func recording(isrc: String?) async throws -> ArtistResponseDAO? {
        guard let isrc else { return nil }
        do {
            return try await client.recording(isrc: isrc).mainArtist.map(ArtistResponseDAO.init)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    private func search(_ name: String) async throws -> ArtistResponseDAO {
        do {
            let artists = try await client.searchArtists(named: name).artists
            guard let artist = artists.first, (artist.score ?? 0) >= Self.minimumSearchScore else {
                return ArtistResponseDAO(artistName: nil, kind: .unknown)
            }
            return ArtistResponseDAO(artist)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ArtistError.unavailable
        }
    }
}

/// Answers already read, by ISRC and by artist name, so the same artist is not asked for twice.
private actor ArtistKindCache {
    private var byISRC: [String: ArtistResponseDAO] = [:]
    private var byName: [String: ArtistResponseDAO] = [:]

    func response(for request: ArtistRequestDAO) -> ArtistResponseDAO? {
        request.isrc.flatMap { byISRC[$0] } ?? byName[request.nameKey]
    }

    func store(_ response: ArtistResponseDAO, for request: ArtistRequestDAO) {
        if let isrc = request.isrc {
            byISRC[isrc] = response
        } else {
            byName[request.nameKey] = response
        }
    }
}
