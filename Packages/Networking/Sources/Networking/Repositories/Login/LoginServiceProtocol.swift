import Foundation

public enum LoginError: Error, Equatable, Sendable {
    /// There is no login service for this provider yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not authorised Playlister to use the provider.
    case notAuthorized
    /// The account has no active subscription, so it cannot play the provider's catalogue.
    case subscriptionRequired
    /// The provider could not be reached or rejected the session.
    case unavailable
}

/// Common contract of every music service login (Apple Music today, Spotify later).
/// Features use it through `LoginRepository` and only say which provider to sign in with.
public protocol LoginServiceProtocol: Sendable {
    /// Starts a session with the provider: checks that the account can be used to play music.
    /// Throws a `LoginError` when the session cannot be started.
    func login(with provider: MusicProvider) async throws
}
