import Foundation

/// Music services the player can sign in with.
public enum MusicProvider: Hashable, Sendable, CaseIterable {
    case spotify
    case appleMusic
    /// Free mode: plays without signing in to a paid music service.
    case free
}

/// Decision of the user, or of the device, about access to a music service.
public enum AuthorizationStatus: Equatable, Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

public enum AuthorizationError: Error, Equatable, Sendable {
    /// There is no authorisation service for this provider yet.
    case unsupportedProvider(MusicProvider)
}

/// Common contract of every music service authorisation (Apple Music today, Spotify later).
/// Features use it through `AuthorizationRepository` and only say which provider to check.
public protocol AuthorizationServiceProtocol: Sendable {
    /// Shows the provider's official sign-in or permission prompt when needed and returns the decision.
    /// Throws `AuthorizationError.unsupportedProvider` when the provider cannot be checked.
    func requestAuthorization(for provider: MusicProvider) async throws -> AuthorizationStatus
}
