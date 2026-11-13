import Foundation

/// Public entry point of the logins: forwards each request to the service of its provider.
public final class LoginRepository: LoginServiceProtocol {
    private let services: [MusicProvider: any LoginServiceProtocol]

    public convenience init() {
        self.init(services: [.appleMusic: AppleMusicLoginService(), .spotify: SpotifyLoginService()])
    }

    /// Lets tests inject fake services.
    init(services: [MusicProvider: any LoginServiceProtocol]) {
        self.services = services
    }

    public func login(with provider: MusicProvider) async throws {
        guard let service = services[provider] else {
            throw LoginError.unsupportedProvider(provider)
        }
        try await service.login(with: provider)
    }
}
