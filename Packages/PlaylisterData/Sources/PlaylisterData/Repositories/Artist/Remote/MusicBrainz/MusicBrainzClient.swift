import Foundation

/// The two MusicBrainz calls the Artist repository makes. Internal, so tests can fake it.
protocol MusicBrainzClientProtocol: Sendable {
    func recording(isrc: String) async throws -> MusicBrainzISRCResponseDAO
    func searchArtists(named name: String) async throws -> MusicBrainzArtistSearchResponseDAO
}

/// Calls the MusicBrainz web service through `NetworkClient`, at most once per `MusicBrainzThrottle.interval`,
/// as MusicBrainz asks, and with a `User-Agent` that names the app.
struct MusicBrainzClient: MusicBrainzClientProtocol {
    static let isrcService = "isrc"
    static let artistService = "artist"

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    init(client: NetworkClient, configuration: RepositoryConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    func recording(isrc: String) async throws -> MusicBrainzISRCResponseDAO {
        let url = try configuration.url(for: Self.isrcService).appendingPathComponent(isrc)
        try await MusicBrainzThrottle.shared.wait()
        return try await client.request(url, method: .get, body: MusicBrainzISRCQueryDAO(), headers: Self.headers)
    }

    func searchArtists(named name: String) async throws -> MusicBrainzArtistSearchResponseDAO {
        let url = try configuration.url(for: Self.artistService)
        try await MusicBrainzThrottle.shared.wait()
        return try await client.request(
            url,
            method: .get,
            body: MusicBrainzArtistSearchQueryDAO(name: name),
            headers: Self.headers
        )
    }

    /// MusicBrainz asks every client for a `User-Agent` with its name, version and a contact.
    /// https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting
    static let userAgent: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "Playlister/\(version) ( \(contact) )"
    }()

    /// How MusicBrainz can reach the app's developers: a web page or an email address.
    static let contact = "https://github.com/Hernandva/Playlister"

    private static var headers: [String: String] {
        ["User-Agent": userAgent, "Accept": "application/json"]
    }
}

/// Spaces the calls to MusicBrainz, which allows one request per second from each client.
actor MusicBrainzThrottle {
    static let shared = MusicBrainzThrottle()
    static let interval: Duration = .milliseconds(1100)

    private let clock = ContinuousClock()
    private var nextSlot: ContinuousClock.Instant?

    /// Returns when the caller may send its request; callers that come together go one interval apart.
    func wait() async throws {
        let now = clock.now
        let slot = max(nextSlot ?? now, now)
        nextSlot = slot.advanced(by: Self.interval)
        try await clock.sleep(until: slot)
    }
}
