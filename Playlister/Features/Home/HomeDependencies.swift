import Foundation

/// Dependency injection container of Home: the only place where its concrete types are built.
@MainActor
final class HomeDependencies {
    init() {}

    func makeUseCase() -> any HomeUseCaseProtocol {
        HomeUseCase()
    }

    func makeViewModel() -> HomeViewModel {
        HomeViewModel(useCase: makeUseCase())
    }
}
