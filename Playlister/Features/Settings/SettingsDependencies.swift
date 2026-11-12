import Foundation
import PlaylisterData

/// Dependency injection container of Settings: the only place where its concrete types are built.
@MainActor
final class SettingsDependencies {
    private let provider: MusicProvider
    private let signOut: @MainActor () -> Void
    private let repository: any SettingsRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - signOut: Goes back to Home, where the user can sign in again or with another service.
    init(
        provider: MusicProvider,
        signOut: @escaping @MainActor () -> Void,
        repository: any SettingsRepositoryProtocol = SettingsRepository()
    ) {
        self.provider = provider
        self.signOut = signOut
        self.repository = repository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// Action of «Sign out».
    func resolveSignOut() -> @MainActor () -> Void {
        signOut
    }

    func resolveRepository() -> any SettingsRepositoryProtocol {
        repository
    }

    func resolveSettingsUseCase() -> any SettingsUseCaseProtocol {
        SettingsUseCase(dependencies: self)
    }

    func resolveSaveSettingsUseCase() -> any SaveSettingsUseCaseProtocol {
        SaveSettingsUseCase(dependencies: self)
    }

    func resolveViewModel() -> SettingsViewModel {
        SettingsViewModel(dependencies: self)
    }
}
