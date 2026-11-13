import Foundation

/// The token calls of Spotify's Accounts service. Internal, so tests can fake it.
protocol SpotifyAccountsClientProtocol: Sendable {
    func exchange(_ body: SpotifyCodeExchangeDAO) async throws -> SpotifyTokenResponseDAO
    func refresh(_ body: SpotifyTokenRefreshDAO) async throws -> SpotifyTokenResponseDAO
}

/// `POST https://accounts.spotify.com/api/token`, form encoded, through `NetworkClient`.
struct SpotifyAccountsClient: SpotifyAccountsClientProtocol {
    private let client: NetworkClient

    init(client: NetworkClient = .shared) {
        self.client = client
    }

    func exchange(_ body: SpotifyCodeExchangeDAO) async throws -> SpotifyTokenResponseDAO {
        try await post(body)
    }

    func refresh(_ body: SpotifyTokenRefreshDAO) async throws -> SpotifyTokenResponseDAO {
        try await post(body)
    }

    private func post<Body: Encodable & Sendable>(_ body: Body) async throws -> SpotifyTokenResponseDAO {
        guard let url = URL(string: SpotifyAuthConfiguration.tokenURL) else {
            throw NetworkError.invalidURL(SpotifyAuthConfiguration.tokenURL)
        }
        return try await client.request(
            url,
            method: .post,
            body: body,
            encoding: .form,
            logLabel: "SpotifyAccountsClient"
        )
    }
}
