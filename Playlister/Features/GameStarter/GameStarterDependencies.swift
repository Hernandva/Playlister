import Foundation
import PlaylisterData

/// Dependency injection container of GameStarter: the only place where its concrete types are built.
@MainActor
final class GameStarterDependencies {
    private let provider: MusicProvider
    private let signOut: @MainActor () -> Void
    private let navigate: @MainActor (GameStarterCoordinator.Route) -> Void
    private let repository: any LastPlaylistRepositoryProtocol
    private let settingsRepository: any SettingsRepositoryProtocol
    /// One view model per container, so the playlist selector hands its choice to the screen on display.
    private lazy var viewModel = GameStarterViewModel(dependencies: self)

    /// - Parameters:
    ///   - provider: The music service the user signed in with in Home.
    ///   - signOut: Goes back to Home from any screen opened from GameStarter (Settings › Sign out).
    ///   - navigate: Pushes a route on the app's navigation stack (Play opens the game with it).
    init(
        provider: MusicProvider,
        signOut: @escaping @MainActor () -> Void,
        navigate: @escaping @MainActor (GameStarterCoordinator.Route) -> Void,
        repository: any LastPlaylistRepositoryProtocol = LastPlaylistRepository(),
        settingsRepository: any SettingsRepositoryProtocol = SettingsRepository()
    ) {
        self.provider = provider
        self.signOut = signOut
        self.navigate = navigate
        self.repository = repository
        self.settingsRepository = settingsRepository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// Goes back to Home. Settings receives it for «Sign out».
    func resolveSignOut() -> @MainActor () -> Void {
        signOut
    }

    /// Opens the game with `playlist` and the game settings. The view model calls it from Play.
    func resolveOpenGame()
        -> @MainActor (GameStarterViewData.Playlist, GameStarterViewData.GameSettings) -> Void {
        { [navigate] playlist, settings in
            navigate(.game(playlist, settings))
        }
    }

    /// Game settings of each music service, from PlaylisterData.
    func resolveSettingsRepository() -> any SettingsRepositoryProtocol {
        settingsRepository
    }

    func resolveGameSettingsUseCase() -> any GameSettingsUseCaseProtocol {
        GameSettingsUseCase(dependencies: self)
    }

    func resolveRepository() -> any LastPlaylistRepositoryProtocol {
        repository
    }

    func resolveLastPlaylistUseCase() -> any LastPlaylistUseCaseProtocol {
        LastPlaylistUseCase(dependencies: self)
    }

    func resolveSaveLastPlaylistUseCase() -> any SaveLastPlaylistUseCaseProtocol {
        SaveLastPlaylistUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameStarterViewModel {
        viewModel
    }

    /// Shows the playlist confirmed in the playlist selector in the selected playlist card.
    func resolveSelectPlaylist() -> @MainActor (GameStarterViewData.Playlist) -> Void {
        { [weak self] playlist in
            self?.viewModel.selectPlaylist(playlist)
        }
    }
}
