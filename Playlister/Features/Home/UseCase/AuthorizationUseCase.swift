import Foundation
import PlaylisterData

protocol AuthorizationUseCaseProtocol: Sendable {
    /// Signs in with every `MusicProvider`, one after another, and returns the state of each one.
    func execute() async throws -> [HomeViewData.ProviderAuthorization]
}

/// Authorisation of the music services shown in Home.
struct AuthorizationUseCase: AuthorizationUseCaseProtocol {
    private let authorization: any AuthorizationServiceProtocol

    /// Resolves what the use case needs from Home's container.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.authorization = dependencies.resolveAuthorization()
    }

    func execute() async throws -> [HomeViewData.ProviderAuthorization] {
        var authorizations: [HomeViewData.ProviderAuthorization] = []
        for musicProvider in MusicProvider.allCases {
            authorizations.append(await askForAuthorization(with: Self.provider(for: musicProvider)))
        }
        return authorizations
    }
}

private extension AuthorizationUseCase {
    func askForAuthorization(with provider: HomeViewModel.Provider) async -> HomeViewData.ProviderAuthorization {
        let result: HomeViewData.Authorization
        do {
            let status = try await authorization.requestAuthorization(for: Self.musicProvider(for: provider))
            result = Self.authorization(for: status)
        } catch {
            result = .unavailable
        }
        return HomeViewData.ProviderAuthorization(provider: provider, authorization: result)
    }

    static func provider(for musicProvider: MusicProvider) -> HomeViewModel.Provider {
        switch musicProvider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        case .free: .free
        }
    }

    static func musicProvider(for provider: HomeViewModel.Provider) -> MusicProvider {
        switch provider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        case .free: .free
        }
    }

    static func authorization(for status: AuthorizationStatus) -> HomeViewData.Authorization {
        switch status {
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        }
    }
}
