import Foundation
import PlaylisterData

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    private let provider: MusicProvider
    private let playlist: GameViewData.Playlist
    private let settings: GameViewData.Settings

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlist: The playlist chosen in ProviderStarter, played by the game.
    ///   - settings: The game settings saved in Settings.
    init(provider: MusicProvider, playlist: GameViewData.Playlist, settings: GameViewData.Settings) {
        self.provider = provider
        self.playlist = playlist
        self.settings = settings
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// The playlist the game is played with.
    func resolvePlaylist() -> GameViewData.Playlist {
        playlist
    }

    /// The game settings the game is played with.
    func resolveSettings() -> GameViewData.Settings {
        settings
    }

    func resolveUseCase() -> any GameUseCaseProtocol {
        GameUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
