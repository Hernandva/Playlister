import Foundation
import PlaylisterData

protocol GamePlaybackTimeUseCaseProtocol: Sendable {
    /// Current time of the song in the player, in seconds of the whole song; 0 when nothing plays.
    func execute(provider: MusicProvider) async -> TimeInterval
}

/// Reads where the player is through the Player repository public API, for the progress bar.
/// MusicKit does not announce time changes, so the view model calls it on a timer while the song plays.
struct GamePlaybackTimeUseCase: GamePlaybackTimeUseCaseProtocol {
    private let repository: any PlayerRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolvePlayerRepository()
    }

    func execute(provider: MusicProvider) async -> TimeInterval {
        // A provider without a player has nothing playing.
        (try? await repository.playbackTime(provider: provider)) ?? 0
    }
}
