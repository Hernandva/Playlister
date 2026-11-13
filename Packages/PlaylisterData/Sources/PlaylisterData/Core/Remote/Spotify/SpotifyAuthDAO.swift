import Foundation

/// Body of `POST /api/token` that trades the authorisation code for the first tokens. Internal.
struct SpotifyCodeExchangeDAO: Encodable, Sendable {
    let grantType = "authorization_code"
    let code: String
    let redirectURI: String
    let clientID: String
    let codeVerifier: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case code
        case redirectURI = "redirect_uri"
        case clientID = "client_id"
        case codeVerifier = "code_verifier"
    }
}

/// Body of `POST /api/token` that renews an expired access token. Internal.
struct SpotifyTokenRefreshDAO: Encodable, Sendable {
    let grantType = "refresh_token"
    let refreshToken: String
    let clientID: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case clientID = "client_id"
    }
}

/// Answer of `POST /api/token`. A refresh may leave `refresh_token` out: the previous one is still valid. Internal.
struct SpotifyTokenResponseDAO: Decodable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

/// The tokens kept in the keychain between launches. Internal.
struct SpotifySessionDAO: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expirationDate: Date

    /// `true` when the access token expires within `margin` seconds, so it is renewed before a call fails.
    func isExpired(at date: Date = Date(), margin: TimeInterval = 60) -> Bool {
        expirationDate.timeIntervalSince(date) <= margin
    }
}
