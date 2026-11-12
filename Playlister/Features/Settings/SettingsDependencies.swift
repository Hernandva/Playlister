import Foundation
import Networking

/// Dependency injection container of Settings: the only place where its concrete types are built.
@MainActor
final class SettingsDependencies {
    private let repository: any SettingsRepositoryProtocol

    init(repository: any SettingsRepositoryProtocol = SettingsRepository()) {
        self.repository = repository
    }

    func resolveRepository() -> any SettingsRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any SettingsUseCaseProtocol {
        SettingsUseCase(dependencies: self)
    }

    func resolveViewModel() -> SettingsViewModel {
        SettingsViewModel(dependencies: self)
    }
}
