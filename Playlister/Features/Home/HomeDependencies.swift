import Foundation
import Networking

/// Dependency injection container of Home: the only place where its concrete types are built.
@MainActor
final class HomeDependencies {
    private let authorization: any AuthorizationServiceProtocol
    private let viewData: HomeViewData

    init() {
        self.authorization = AuthorizationRepository()
        self.viewData = HomeViewData()
    }

    /// Authorisation of the music services, from Networking.
    func resolveAuthorization() -> any AuthorizationServiceProtocol {
        authorization
    }

    /// Shared data of Home: the use case writes it and the view model reads it.
    func resolveViewData() -> HomeViewData {
        viewData
    }

    func resolveAuthorizationUseCase() -> any AuthorizationUseCaseProtocol {
        AuthorizationUseCase(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
