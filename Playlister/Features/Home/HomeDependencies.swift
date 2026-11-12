import Foundation
import Networking

/// Dependency injection container of Home: the only place where its concrete types are built.
@MainActor
final class HomeDependencies {
    private let authorization: any AuthorizationServiceProtocol

    init() {
        self.authorization = AuthorizationRepository()
    }

    /// Authorisation of the music services, from Networking.
    func resolveAuthorization() -> any AuthorizationServiceProtocol {
        authorization
    }

    func resolveAuthorizationUseCase() -> any AuthorizationUseCaseProtocol {
        AuthorizationUseCase(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
