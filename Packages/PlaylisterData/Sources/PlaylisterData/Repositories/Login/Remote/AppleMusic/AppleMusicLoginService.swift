import MusicKit

/// Apple Music login. Internal: the app only sees `LoginServiceProtocol`.
protocol AppleMusicLoginServiceProtocol: LoginServiceProtocol {}

/// Checks the authorisation, reaches the Apple Music API (`AppleMusicAPIClient`) to validate the session and checks
/// with MusicKit that the subscription can play the catalogue: the API has no endpoint for the subscription.
struct AppleMusicLoginService: AppleMusicLoginServiceProtocol {
    private let client = AppleMusicAPIClient()

    func login(with provider: MusicProvider) async throws {
        guard provider == .appleMusic else {
            throw LoginError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw LoginError.notAuthorized
        }
        let subscription: MusicSubscription
        do {
            // Fetching the storefront validates the developer and user tokens against the Apple Music API.
            _ = try await client.storefront()
            subscription = try await MusicSubscription.current
        } catch {
            throw LoginError.unavailable
        }
        guard subscription.canPlayCatalogContent else {
            throw LoginError.subscriptionRequired
        }
    }
}
