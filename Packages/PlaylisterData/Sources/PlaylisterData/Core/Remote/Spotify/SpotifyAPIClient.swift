import Foundation

/// Calls the Spotify Web API (`https://api.spotify.com/v1/`) through `NetworkClient` with the session's token.
/// Internal: shared by the Spotify services of every repository, like `AppleMusicAPIClient` for Apple Music.
protocol SpotifyAPIClientProtocol: Sendable {
    /// GETs `path` (e.g. `me`) with the token and decodes the JSON response.
    func get<Response: Decodable & Sendable>(_ path: String, accessToken: String) async throws -> Response
}

struct SpotifyAPIClient: SpotifyAPIClientProtocol {
    static let configuration = RepositoryConfiguration(
        baseURL: "https://api.spotify.com/v1",
        serviceNames: ["me"]
    )

    private let client: NetworkClient

    init(client: NetworkClient = .shared) {
        self.client = client
    }

    func get<Response: Decodable & Sendable>(_ path: String, accessToken: String) async throws -> Response {
        let url = try Self.configuration.url(for: path)
        let headers = ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
        return try await client.request(
            url,
            method: .get,
            body: SpotifyEmptyQueryDAO?.none,
            headers: headers,
            logLabel: "SpotifyAPIClient"
        )
    }
}

/// A GET without query parameters. Internal.
struct SpotifyEmptyQueryDAO: Encodable, Sendable {}
