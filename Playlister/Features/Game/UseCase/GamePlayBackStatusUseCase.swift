import Foundation
import PlaylisterData

protocol GamePlayBackStatusUseCaseProtocol: Sendable {
    /// Where the player is: the current time of the song and whether it is sounding.
    /// Nothing plays (0, not playing) when the provider has no player.
    func execute(provider: MusicProvider) async -> GameViewData.PlaybackReading
}

/// Reads the player's time and status through the Player repository public API, for the progress bar and to
/// notice a song that stops on its own. MusicKit announces neither, so the view model calls it on a timer.
struct GamePlayBackStatusUseCase: GamePlayBackStatusUseCaseProtocol {
    private let repository: any PlayerRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolvePlayerRepository()
    }

    func execute(provider: MusicProvider) async -> GameViewData.PlaybackReading {
        // A provider without a player has nothing playing.
        let time = (try? await repository.playbackTime(provider: provider)) ?? 0
        let status = (try? await repository.status(provider: provider)) ?? .stopped
        return GameViewData.PlaybackReading(time: time, isPlaying: status == .playing)
    }
}
