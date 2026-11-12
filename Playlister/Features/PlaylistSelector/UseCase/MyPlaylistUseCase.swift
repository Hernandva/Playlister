import Foundation
import PlaylisterData

protocol MyPlaylistUseCaseProtocol: Sendable {
    /// Returns the user's own playlists, most recently played first.
    /// The view model adds them to the `library` of its `PlaylistSelectorViewData`.
    func execute() async throws -> [PlaylistSelectorViewData.Playlist]
}

/// Request sent to the Playlists repository: the music service whose library is read.
struct MyPlaylistsRequest: LibraryPlaylistsRequestProtocol {
    let provider: MusicProvider
}

/// «Your playlists»: reads the user's library through the Playlists repository public API.
struct MyPlaylistUseCase: MyPlaylistUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any PlaylistsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> [PlaylistSelectorViewData.Playlist] {
        let response = try await repository.fetchLibrary(MyPlaylistsRequest(provider: provider))
        return response.playlists.map(PlaylistItemMapper.playlist(from:))
    }
}
