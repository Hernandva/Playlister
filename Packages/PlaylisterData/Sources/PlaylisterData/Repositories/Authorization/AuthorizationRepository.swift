import Foundation

/// Public entry point of the authorisations: forwards each request to the service of its provider.
public final class AuthorizationRepository: AuthorizationServiceProtocol {
    private let services: [MusicProvider: any AuthorizationServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicAuthorizationService(), .spotify: SpotifyAuthorizationService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any AuthorizationServiceProtocol]) {
        self.services = services
    }

    public func requestAuthorization(for provider: MusicProvider) async throws -> AuthorizationStatus {
        guard let service = services[provider] else {
            throw AuthorizationError.unsupportedProvider(provider)
        }
        return try await service.requestAuthorization(for: provider)
    }
}
