import Foundation
import Networking

protocol SaveLastPlaylistUseCaseProtocol: Sendable {
    /// Stores `playlist` as the last playlist of the music service the user signed in with.
    func execute(playlist: ProviderStarterViewData.Playlist) async throws
}

/// Playlist handed to the LastPlaylist repository, mapped from the ViewData type.
struct SavedPlaylist: LastPlaylistItemProtocol {
    let id: String
    let name: String
    let songCount: Int
    let coverURLs: [URL]
}

/// Saves the playlist the game starts with, so it is the last playlist next time.
struct SaveLastPlaylistUseCase: SaveLastPlaylistUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any LastPlaylistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `ProviderStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ProviderStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute(playlist: ProviderStarterViewData.Playlist) async throws {
        let savedPlaylist = SavedPlaylist(
            id: playlist.id,
            name: playlist.name,
            songCount: playlist.songCount,
            coverURLs: playlist.covers
        )
        try await repository.saveLastPlaylist(savedPlaylist, for: provider)
    }
}
