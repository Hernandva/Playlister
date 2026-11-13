import Foundation

/// Spotify login. Internal: the app only sees `LoginServiceProtocol`.
protocol SpotifyLoginServiceProtocol: LoginServiceProtocol {}

/// The account of `GET /v1/me`. Only `product` matters: `premium`, `free` or `open`. Internal.
struct SpotifyUserDAO: Decodable, Sendable, Equatable {
    let id: String
    let product: String?

    var isPremium: Bool { product == "premium" }
}

/// Signs in with Spotify's page when there is no session (OAuth with PKCE), validates the token with
/// `GET /v1/me` and requires Premium: Spotify only lets Premium accounts control the playback.
struct SpotifyLoginService: SpotifyLoginServiceProtocol {
    static let userService = "me"

    private let session: any SpotifySessionProtocol
    private let client: any SpotifyAPIClientProtocol

    init(
        session: any SpotifySessionProtocol = SpotifySession.shared,
        client: any SpotifyAPIClientProtocol = SpotifyAPIClient()
    ) {
        self.session = session
        self.client = client
    }

    func login(with provider: MusicProvider) async throws {
        guard provider == .spotify else {
            throw LoginError.unsupportedProvider(provider)
        }
        let user: SpotifyUserDAO
        do {
            user = try await currentUser()
        } catch is CancellationError {
            throw CancellationError()
        } catch SpotifyAuthError.cancelled {
            throw LoginError.notAuthorized
        } catch {
            #if DEBUG
            print("[SpotifyLoginService] login failed as unavailable: \(error)")
            #endif
            throw LoginError.unavailable
        }
        guard user.isPremium else {
            throw LoginError.subscriptionRequired
        }
    }
}

private extension SpotifyLoginService {
    /// Reads the account. When Spotify rejects the token (401), forgets it and signs in once more.
    func currentUser() async throws -> SpotifyUserDAO {
        do {
            return try await fetchUser()
        } catch NetworkError.unacceptableStatusCode(401) {
            await session.invalidate()
            return try await fetchUser()
        }
    }

    func fetchUser() async throws -> SpotifyUserDAO {
        let token = try await session.accessToken(interactive: true)
        return try await client.get(Self.userService, accessToken: token)
    }
}
