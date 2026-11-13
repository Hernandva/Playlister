import Foundation

/// Public API of the Artist repository. Features depend on this protocol, never on the concrete class.
public protocol ArtistRepositoryProtocol: Sendable {
    /// Whether the main artist of a song is a solo artist or a group, from MusicBrainz: by the song's ISRC when it
    /// has one, and by searching the artist's name when there is none or the ISRC tells nothing. An artist
    /// MusicBrainz does not know is `.unknown`, not an error. Throws `ArtistError.unavailable`; a cancelled call
    /// rethrows `CancellationError`.
    func fetchKind(_ request: some ArtistRequestProtocol) async throws -> any ArtistResponseProtocol
}

/// Asks MusicBrainz what kind of artist sings a song.
/// Flow: ArtistRequestProtocol -> ArtistRequestDAO -> MusicBrainz -> MusicBrainz…DAO -> ArtistResponseDAO.
/// Answers are kept in memory for the life of the repository, by ISRC and by artist name.
public final class ArtistRepository: ArtistRepositoryProtocol {
    /// MusicBrainz web service, version 2. `isrc` looks a recording up by its ISRC, `artist` searches artists.
    public static let configuration = RepositoryConfiguration(
        baseURL: "https://musicbrainz.org/ws/2",
        serviceNames: [MusicBrainzClient.isrcService, MusicBrainzClient.artistService]
    )
    /// Lowest search score (0…100) for an artist found by name to count as the song's artist.
    static let minimumSearchScore = 90

    private let client: any MusicBrainzClientProtocol
    private let cache = ArtistKindCache()

    public convenience init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = ArtistRepository.configuration
    ) {
        self.init(client: MusicBrainzClient(client: client, configuration: configuration))
    }

    /// Lets tests inject a fake MusicBrainz.
    init(client: any MusicBrainzClientProtocol) {
        self.client = client
    }

    public func fetchKind(_ request: some ArtistRequestProtocol) async throws -> any ArtistResponseProtocol {
        let requestDAO = ArtistRequestDAO(request)
        if let cached = await cache.response(for: requestDAO) {
            return cached
        }
        let response = try await lookUp(requestDAO)
        await cache.store(response, for: requestDAO)
        return response
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
