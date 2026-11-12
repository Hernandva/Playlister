import Foundation
import PlaylisterData

protocol PlaylistsUseCaseProtocol: Sendable {
    /// Returns the recommended and the user's playlists of the music service the user signed in with.
    /// The view model adds them to its `PlaylistSelectorViewData`.
    func execute() async throws -> PlaylistSelectorViewData.Playlists
}

/// Request sent to the Playlists repository: the music service and the recommended playlists.
struct PlaylistsRequest: PlaylistsRequestProtocol {
    let provider: MusicProvider
    let recommendedPlaylistIDs: [String]
}

/// Business logic of PlaylistSelector: calls the Playlists repository public API and returns only the data of its
/// response, mapped out of the PlaylisterData types.
struct PlaylistsUseCase: PlaylistsUseCaseProtocol {
    /// Apple Music catalogue identifiers of the recommended «Hitster» playlists, in the order they are shown.
    /// It is the last part of the playlist's link, e.g. music.apple.com/es/playlist/hitster/pl.u-DdANxEPFj4Jyvq.
    /// Add more by hand; they are all read in one request.
    private static let recommendedPlaylistIDs = [
        "pl.u-DdANxEPFj4Jyvq"
    ]

    private let provider: MusicProvider
    private let repository: any PlaylistsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> PlaylistSelectorViewData.Playlists {
        let request = PlaylistsRequest(provider: provider, recommendedPlaylistIDs: Self.recommendedPlaylistIDs)
        let response = try await repository.fetch(request)
        return PlaylistSelectorViewData.Playlists(
            recommended: response.recommended.map(Self.playlist(from:)),
            library: response.library.map(Self.playlist(from:))
        )
    }
}

private extension PlaylistsUseCase {
    static func playlist(from item: any PlaylistsItemProtocol) -> PlaylistSelectorViewData.Playlist {
        PlaylistSelectorViewData.Playlist(
            id: item.id,
            name: item.name,
            curatorName: item.curatorName,
            covers: item.artworkURL.map { [$0] } ?? []
        )
    }
}
