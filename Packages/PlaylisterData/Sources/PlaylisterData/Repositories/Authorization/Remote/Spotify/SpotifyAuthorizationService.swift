import Foundation

/// Spotify authorisation. Internal: the app only sees `AuthorizationServiceProtocol`.
protocol SpotifyAuthorizationServiceProtocol: AuthorizationServiceProtocol {}

/// Spotify has no system permission like MusicKit: the user consents on Spotify's page during the login
/// (`SpotifyLoginService`). So it always answers `authorized` and never shows anything, which lets Home
/// offer «Continue with Spotify» and start the login when it is tapped.
struct SpotifyAuthorizationService: SpotifyAuthorizationServiceProtocol {
    func requestAuthorization(for provider: MusicProvider) async throws -> AuthorizationStatus {
        guard provider == .spotify else {
            throw AuthorizationError.unsupportedProvider(provider)
        }
        return .authorized
    }
}
