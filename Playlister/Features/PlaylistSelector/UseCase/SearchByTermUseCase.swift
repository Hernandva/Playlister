import Foundation
import PlaylisterData

protocol SearchByTermUseCaseProtocol: Sendable {
    /// Returns one page of the catalogue playlists found with `term`, starting at `offset`.
    /// The view model adds it to the `search` of its `PlaylistSelectorViewData`.
    func execute(term: String, offset: Int) async throws -> PlaylistSelectorViewData.SearchPage
}

/// Request sent to the Playlists repository: the music service, the term and where the page starts.
struct PlaylistsSearchRequest: PlaylistsSearchRequestProtocol {
    let provider: MusicProvider
    let term: String
    let offset: Int
}

/// Search results: searches the catalogue's playlists with the text of «Search playlists», one page at a time,
/// through the Playlists repository public API.
struct SearchByTermUseCase: SearchByTermUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any PlaylistsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute(term: String, offset: Int) async throws -> PlaylistSelectorViewData.SearchPage {
        let request = PlaylistsSearchRequest(provider: provider, term: term, offset: offset)
        let response = try await repository.search(request)
        return PlaylistSelectorViewData.SearchPage(
            playlists: response.playlists.map(PlaylistItemMapper.playlist(from:)),
            nextOffset: offset + response.playlists.count,
            hasMore: response.hasMore
        )
    }
}
