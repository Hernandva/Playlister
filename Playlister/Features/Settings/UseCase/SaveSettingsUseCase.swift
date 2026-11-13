import Foundation
import PlaylisterData

protocol SaveSettingsUseCaseProtocol: Sendable {
    /// Stores `game` as the game settings of the music service the user signed in with, replacing the previous ones.
    func execute(game: SettingsViewData.Game) async throws
}

/// Saves the game settings through the Settings repository public API.
struct SaveSettingsUseCase: SaveSettingsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute(game: SettingsViewData.Game) async throws {
        try await repository.saveSettings(SavedSettings(game), for: provider)
    }
}

/// The game settings in the shape the Settings repository stores.
private struct SavedSettings: GameSettingsProtocol {
    let playbackMode: SettingsPlaybackMode
    let clipSeconds: Int
    let clipStart: SettingsClipStart
    let gameMode: SettingsGameMode
    let bingoLevel: SettingsBingoLevel

    init(_ game: SettingsViewData.Game) {
        self.playbackMode = game.playback == .fullSong ? .fullSong : .clip
        self.clipSeconds = game.clipSeconds
        self.clipStart = game.clipStart == .beginning ? .beginning : .random
        self.gameMode = game.mode == .bingo ? .bingo : .classic
        // The id always comes from a level of the repository; the default only guards against a wrong one.
        self.bingoLevel = SettingsBingoLevel(rawValue: game.bingoLevel) ?? .beginner
    }
}
