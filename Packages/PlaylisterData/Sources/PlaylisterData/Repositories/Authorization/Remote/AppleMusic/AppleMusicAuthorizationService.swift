import MusicKit

/// Apple Music authorisation. Internal: the app only sees `AuthorizationServiceProtocol`.
protocol AppleMusicAuthorizationServiceProtocol: AuthorizationServiceProtocol {}

/// Wraps MusicKit: shows the system's Apple Music prompt the first time and returns the stored decision afterwards.
struct AppleMusicAuthorizationService: AppleMusicAuthorizationServiceProtocol {
    func requestAuthorization(for provider: MusicProvider) async throws -> AuthorizationStatus {
        guard provider.usesAppleMusic else {
            throw AuthorizationError.unsupportedProvider(provider)
        }
        switch await MusicAuthorization.request() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
}
