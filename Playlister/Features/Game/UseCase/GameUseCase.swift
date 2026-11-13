import Foundation

protocol GameUseCaseProtocol: Sendable {
    /// Returns only the data of the response. The view model adds it to its `GameViewData`.
    func execute() async throws -> GameViewData.Content
}

/// Business logic of Game.
/// When the feature needs remote data, add a `resolve<Name>()` function to GameDependencies,
/// resolve it in `init(dependencies:)` and map its public response protocol into the type this use case returns.
struct GameUseCase: GameUseCaseProtocol {
    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {}

    func execute() async throws -> GameViewData.Content {
        GameViewData.Content()
    }
}
