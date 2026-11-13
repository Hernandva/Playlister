import Foundation
import PlaylisterData

protocol LastPlaylistUseCaseProtocol: Sendable {
    /// Returns the last playlist saved for the music service the user signed in with, or `nil` when there is none.
    /// The view model adds it to its `GameStarterViewData`.
    func execute() async throws -> GameStarterViewData.Playlist?
}

/// Request sent to the Provider repository: the music service the user signed in with in Home.
struct LastPlaylistRequest: LastPlaylistRequestProtocol {
    let provider: MusicProvider
}

/// Business logic of GameStarter: calls the Provider repository public API and returns only the data
/// of its response, mapped out of the PlaylisterData types.
struct LastPlaylistUseCase: LastPlaylistUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any LastPlaylistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> GameStarterViewData.Playlist? {
        let response = try await repository.fetch(LastPlaylistRequest(provider: provider))
        return response.lastPlaylist.map(Self.playlist(from:))
    }
}

private extension LastPlaylistUseCase {
    static func playlist(from playlist: any LastPlaylistItemProtocol) -> GameStarterViewData.Playlist {
        GameStarterViewData.Playlist(
            id: playlist.id,
            name: playlist.name,
            songCount: playlist.songCount,
            covers: playlist.coverURLs
        )
    }
}
