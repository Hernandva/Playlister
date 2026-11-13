import Foundation

/// Hands out a valid Spotify access token. Internal: shared by the Spotify services of every repository.
protocol SpotifySessionProtocol: Sendable {
    /// A token that is not expired: the stored one, a renewed one or, when `interactive`, one from a new sign-in.
    /// Throws `SpotifyAuthError.signInRequired` when there is no session and `interactive` is `false`.
    func accessToken(interactive: Bool) async throws -> String
    /// Forgets the tokens, e.g. after Spotify rejects them, so the next call signs in again.
    func invalidate() async
}

/// One session for the whole app, kept in the keychain. Being an actor, two calls never sign in or refresh at once.
actor SpotifySession: SpotifySessionProtocol {
    static let shared = SpotifySession()

    private let configuration: SpotifyAuthConfiguration
    private let storage: any SpotifySessionStorageProtocol
    private let accounts: any SpotifyAccountsClientProtocol
    private let authenticator: any SpotifyWebAuthenticatorProtocol
    private var session: SpotifySessionDAO?

    init(
        configuration: SpotifyAuthConfiguration = .main,
        storage: any SpotifySessionStorageProtocol = SpotifyKeychainSessionStorage(),
        accounts: any SpotifyAccountsClientProtocol = SpotifyAccountsClient(),
        authenticator: any SpotifyWebAuthenticatorProtocol = SpotifyWebAuthenticator()
    ) {
        self.configuration = configuration
        self.storage = storage
        self.accounts = accounts
        self.authenticator = authenticator
        self.session = storage.load()
    }

    func accessToken(interactive: Bool) async throws -> String {
        if let session, !session.isExpired() {
            return session.accessToken
        }
        if let session, let renewed = try? await refresh(session) {
            return renewed.accessToken
        }
        guard interactive else {
            throw SpotifyAuthError.signInRequired
        }
        return try await signIn().accessToken
    }

    func invalidate() {
        session = nil
        storage.delete()
    }
}

private extension SpotifySession {
    func refresh(_ current: SpotifySessionDAO) async throws -> SpotifySessionDAO {
        let response = try await accounts.refresh(
            SpotifyTokenRefreshDAO(refreshToken: current.refreshToken, clientID: configuration.clientID)
        )
        return try store(response, previousRefreshToken: current.refreshToken)
    }

    func signIn() async throws -> SpotifySessionDAO {
        guard !configuration.clientID.isEmpty else {
            throw SpotifyAuthError.missingClientID
        }
        let pkce = SpotifyPKCE()
        let callback = try await authenticator.authenticate(
            url: try authorizeURL(pkce: pkce),
            callbackScheme: SpotifyAuthConfiguration.callbackScheme
        )
        let code = try Self.code(from: callback, state: pkce.state)
        let response = try await accounts.exchange(
            SpotifyCodeExchangeDAO(
                code: code,
                redirectURI: configuration.redirectURI,
                clientID: configuration.clientID,
                codeVerifier: pkce.verifier
            )
        )
        return try store(response, previousRefreshToken: nil)
    }

    func store(_ response: SpotifyTokenResponseDAO, previousRefreshToken: String?) throws -> SpotifySessionDAO {
        guard let refreshToken = response.refreshToken ?? previousRefreshToken else {
            throw SpotifyAuthError.invalidCallback
        }
        let renewed = SpotifySessionDAO(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expirationDate: Date().addingTimeInterval(TimeInterval(response.expiresIn))
        )
        session = renewed
        // A session that cannot be saved still works until the app is closed.
        try? storage.save(renewed)
        return renewed
    }

    func authorizeURL(pkce: SpotifyPKCE) throws -> URL {
        var components = URLComponents(string: SpotifyAuthConfiguration.authorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "state", value: pkce.state),
            URLQueryItem(name: "scope", value: SpotifyAuthConfiguration.scopes.joined(separator: " "))
        ]
        guard let url = components?.url else {
            throw NetworkError.invalidURL(SpotifyAuthConfiguration.authorizeURL)
        }
        return url
    }

    /// The `code` of Spotify's redirect. An `error` (e.g. `access_denied`) means the user refused.
    static func code(from callback: URL, state: String) throws -> String {
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        guard value("state") == state else {
            throw SpotifyAuthError.invalidCallback
        }
        if value("error") != nil {
            throw SpotifyAuthError.cancelled
        }
        guard let code = value("code"), !code.isEmpty else {
            throw SpotifyAuthError.invalidCallback
        }
        return code
    }
}
