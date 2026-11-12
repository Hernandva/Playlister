import Foundation
import Observation

@MainActor
@Observable
final class PlaylistSelectorViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: PlaylistSelectorViewData

    /// Text of the search field. Filters both carousels by playlist name.
    var searchText = ""
    /// Playlist whose confirmation sheet is shown, or `nil` when the sheet is closed.
    var pendingPlaylist: PlaylistSelectorViewData.Playlist?
    /// Set once the user selected a playlist: the view closes once the sheet has closed.
    private(set) var wantsToClose = false

    private let playlistsUseCase: any PlaylistsUseCaseProtocol
    private let selectPlaylist: @MainActor (PlaylistSelectorViewData.Playlist) -> Void

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: PlaylistSelectorDependencies) {
        self.viewData = PlaylistSelectorViewData(provider: dependencies.resolveProvider())
        self.playlistsUseCase = dependencies.resolvePlaylistsUseCase()
        self.selectPlaylist = dependencies.resolveSelectPlaylist()
    }

    /// «Hitster» playlists that match the search.
    var recommended: [PlaylistSelectorViewData.Playlist] {
        filtered(viewData.playlists?.recommended ?? [])
    }

    /// The user's playlists that match the search.
    var library: [PlaylistSelectorViewData.Playlist] {
        filtered(viewData.playlists?.library ?? [])
    }

    /// `true` while the user is searching.
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Number shown next to the recommended header.
    var recommendedCountText: String {
        recommended.count.formatted()
    }

    /// Shown in «Your playlists» when the user has none in the music service.
    var emptyLibraryMessage: String {
        String(localized: "playlistSelector.library.empty \(viewData.providerName)")
    }

    /// Song count under the playlist name: «312 songs».
    func songCountText(for playlist: PlaylistSelectorViewData.Playlist) -> String {
        String(localized: "playlistSelector.songs \(playlist.songCount)")
    }

    /// Message of the confirmation sheet: «312 songs · Apple Music», then the question.
    func confirmationMessage(for playlist: PlaylistSelectorViewData.Playlist) -> String {
        let details = "\(songCountText(for: playlist)) · \(viewData.providerName)"
        return details + "\n" + String(localized: "playlistSelector.confirm.question")
    }

    /// A playlist was tapped: asks the user to confirm it.
    func didTap(_ playlist: PlaylistSelectorViewData.Playlist) {
        wantsToClose = false
        pendingPlaylist = playlist
    }

    /// «Select playlist»: hands the playlist to the feature that opened the selector and asks the view to close.
    func confirmSelection() {
        guard let playlist = pendingPlaylist else { return }
        selectPlaylist(playlist)
        wantsToClose = true
        pendingPlaylist = nil
    }

    /// «Cancel» in the confirmation sheet.
    func cancelSelection() {
        pendingPlaylist = nil
    }

    func load() async {
        state = .loading
        do {
            viewData.playlists = try await playlistsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "playlistSelector.error \(viewData.providerName)"))
        }
    }

    private func filtered(_ playlists: [PlaylistSelectorViewData.Playlist]) -> [PlaylistSelectorViewData.Playlist] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return playlists }
        return playlists.filter { $0.name.localizedStandardContains(query) }
    }
}
