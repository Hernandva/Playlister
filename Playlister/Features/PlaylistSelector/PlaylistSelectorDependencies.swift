import Foundation
import PlaylisterData

/// Dependency injection container of PlaylistSelector: the only place where its concrete types are built.
@MainActor
final class PlaylistSelectorDependencies {
    private let provider: MusicProvider
    private let selectPlaylist: @MainActor (PlaylistSelectorViewData.Playlist) -> Void
    private let repository: any PlaylistsRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - selectPlaylist: Hands the playlist the user confirmed back to the feature that opened the selector.
    init(
        provider: MusicProvider,
        selectPlaylist: @escaping @MainActor (PlaylistSelectorViewData.Playlist) -> Void,
        repository: any PlaylistsRepositoryProtocol = PlaylistsRepository()
    ) {
        self.provider = provider
        self.selectPlaylist = selectPlaylist
        self.repository = repository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// Action of «Select playlist» in the confirmation sheet.
    func resolveSelectPlaylist() -> @MainActor (PlaylistSelectorViewData.Playlist) -> Void {
        selectPlaylist
    }

    func resolveRepository() -> any PlaylistsRepositoryProtocol {
        repository
    }

    func resolvePlaylistsUseCase() -> any PlaylistsUseCaseProtocol {
        PlaylistsUseCase(dependencies: self)
    }

    func resolveViewModel() -> PlaylistSelectorViewModel {
        PlaylistSelectorViewModel(dependencies: self)
    }
}
