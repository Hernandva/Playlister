import Foundation

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    init() {}

    func resolveUseCase() -> any GameUseCaseProtocol {
        GameUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
