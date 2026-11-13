import Foundation
import PlaylisterData

protocol StopGameSongUseCaseProtocol: Sendable {
    /// Stops the song that is playing, e.g. when the user leaves the game.
    func execute(provider: MusicProvider) async
}

/// Stops the game's playback through the Player repository public API.
struct StopGameSongUseCase: StopGameSongUseCaseProtocol {
    private let repository: any PlayerRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolvePlayerRepository()
    }

    func execute(provider: MusicProvider) async {
        // A provider without a player has nothing playing, so there is nothing to stop.
        try? await repository.stop(provider: provider)
    }
}
