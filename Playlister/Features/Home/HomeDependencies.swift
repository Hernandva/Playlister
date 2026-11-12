import Foundation
import Networking

/// Dependency injection container of Home: the only place where its concrete types are built.
@MainActor
final class HomeDependencies {
    private let authorization: any AuthorizationServiceProtocol
    private let login: any LoginServiceProtocol
    /// Weak: the coordinator owns this container, so a strong reference would retain both.
    private weak var coordinator: (any HomeCoordinatorProtocol)?

    init() {
        self.authorization = AuthorizationRepository()
        self.login = LoginRepository()
    }

    /// Called by `HomeCoordinator` when it is created, so the view model can navigate through it.
    func register(coordinator: any HomeCoordinatorProtocol) {
        self.coordinator = coordinator
    }

    /// Navigation of Home, or `nil` when no coordinator was registered.
    func resolveCoordinator() -> (any HomeCoordinatorProtocol)? {
        coordinator
    }

    /// Authorisation of the music services, from Networking.
    func resolveAuthorization() -> any AuthorizationServiceProtocol {
        authorization
    }

    /// Login in the music services, from Networking.
    func resolveLogin() -> any LoginServiceProtocol {
        login
    }

    func resolveStartProviderUseCase() -> any StartProviderUseCaseProtocol {
        StartProviderUseCase(dependencies: self)
    }

    func resolveAuthorizationUseCase() -> any AuthorizationUseCaseProtocol {
        AuthorizationUseCase(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
