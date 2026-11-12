import MusicKit

/// Apple Music login. Internal: the app only sees `LoginServiceProtocol`.
protocol AppleMusicLoginServiceProtocol: LoginServiceProtocol {}

/// Wraps MusicKit: checks the authorisation, reaches Apple Music to validate the session
/// and checks that the subscription can play the catalogue.
struct AppleMusicLoginService: AppleMusicLoginServiceProtocol {
    func login(with provider: MusicProvider) async throws {
        guard provider == .appleMusic else {
            throw LoginError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw LoginError.notAuthorized
        }
        let subscription: MusicSubscription
        do {
            // Fetching the storefront validates the developer and user tokens against Apple Music.
            _ = try await MusicDataRequest.currentCountryCode
            subscription = try await MusicSubscription.current
        } catch {
            throw LoginError.unavailable
        }
        guard subscription.canPlayCatalogContent else {
            throw LoginError.subscriptionRequired
        }
    }
}
