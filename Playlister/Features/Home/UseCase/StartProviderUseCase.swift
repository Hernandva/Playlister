import Foundation
import PlaylisterData

protocol StartProviderUseCaseProtocol: Sendable {
    /// Signs in with `provider`. Throws a `HomeViewData.LoginFailure` when the session cannot be started.
    func execute(provider: HomeViewModel.Provider) async throws
}

/// Login in the music service chosen in Home.
struct StartProviderUseCase: StartProviderUseCaseProtocol {
    private let login: any LoginServiceProtocol

    /// Resolves what the use case needs from Home's container.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.login = dependencies.resolveLogin()
    }

    func execute(provider: HomeViewModel.Provider) async throws {
        do {
            try await login.login(with: Self.musicProvider(for: provider))
        } catch let error as LoginError {
            throw Self.failure(for: error)
        } catch {
            throw HomeViewData.LoginFailure.unavailable
        }
    }
}

private extension StartProviderUseCase {
    static func musicProvider(for provider: HomeViewModel.Provider) -> MusicProvider {
        switch provider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        }
    }

    static func failure(for error: LoginError) -> HomeViewData.LoginFailure {
        switch error {
        case .notAuthorized: .notAuthorized
        case .subscriptionRequired: .subscriptionRequired
        case .unsupportedProvider, .unavailable: .unavailable
        }
    }
}
