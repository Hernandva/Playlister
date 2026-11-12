import Foundation
import Networking

protocol AuthorizationUseCaseProtocol: Sendable {
    /// Signs in with every `MusicProvider`, one after another, and stores each state in the view data.
    func execute() async throws
}

/// Authorisation of the music services shown in Home.
/// Writes the results into the shared `HomeViewData` instead of returning them.
struct AuthorizationUseCase: AuthorizationUseCaseProtocol {
    private let authorization: any AuthorizationServiceProtocol
    private let viewData: HomeViewData

    /// Resolves what the use case needs from Home's container.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.authorization = dependencies.resolveAuthorization()
        self.viewData = dependencies.resolveViewData()
    }

    func execute() async throws {
        for musicProvider in MusicProvider.allCases {
            await askForAuthorization(with: Self.provider(for: musicProvider))
        }
    }
}

private extension AuthorizationUseCase {
    func askForAuthorization(with provider: HomeViewModel.Provider) async {
        let result: HomeViewData.Authorization
        do {
            let status = try await authorization.requestAuthorization(for: Self.musicProvider(for: provider))
            result = Self.authorization(for: status)
        } catch {
            result = .unavailable
        }
        await viewData.update(result, for: provider)
    }

    static func provider(for musicProvider: MusicProvider) -> HomeViewModel.Provider {
        switch musicProvider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        }
    }

    static func musicProvider(for provider: HomeViewModel.Provider) -> MusicProvider {
        switch provider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
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
