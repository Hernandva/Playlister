import Foundation
import Observation

/// State of the selector. Each section (search, «Hitster», «Your playlists») loads on its own and has its own
/// state, so none waits for the others and the screen never blocks.
@MainActor
@Observable
final class PlaylistSelectorViewModel {
    typealias Playlist = PlaylistSelectorViewData.Playlist

    /// State of one section.
    enum SectionState: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    /// Time the search waits after the last keystroke before it asks the music service.
    private static let searchDebounce: Duration = .milliseconds(400)

    private(set) var hitsterState: SectionState = .idle
    private(set) var libraryState: SectionState = .idle
    private(set) var searchState: SectionState = .idle
    /// `true` while the next page of the search loads.
    private(set) var isLoadingMoreResults = false
    /// `true` when the next page of the search could not load: the carousel offers to try again.
    private(set) var loadMoreResultsFailed = false
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: PlaylistSelectorViewData

    /// Text of «Search playlists». Searches the catalogue and filters «Hitster» and «Your playlists» by name.
    var searchText = ""
    /// Playlist whose confirmation sheet is shown, or `nil` when the sheet is closed.
    var pendingPlaylist: Playlist?
    /// Set once the user selected a playlist: the view closes once the sheet has closed.
    private(set) var wantsToClose = false

    private let myPlaylistUseCase: any MyPlaylistUseCaseProtocol
    private let hitsterPlayListUseCase: any HitsterPlayListUseCaseProtocol
    private let searchByTermUseCase: any SearchByTermUseCaseProtocol
    private let selectPlaylist: @MainActor (Playlist) -> Void

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: PlaylistSelectorDependencies) {
        self.viewData = PlaylistSelectorViewData(provider: dependencies.resolveProvider())
        self.myPlaylistUseCase = dependencies.resolveMyPlaylistUseCase()
        self.hitsterPlayListUseCase = dependencies.resolveHitsterPlayListUseCase()
        self.searchByTermUseCase = dependencies.resolveSearchByTermUseCase()
        self.selectPlaylist = dependencies.resolveSelectPlaylist()
    }

    // MARK: Sections

    /// The search text without surrounding spaces.
    var searchTerm: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` while the user is searching.
    var isSearching: Bool {
        !searchTerm.isEmpty
    }

    /// «Hitster» playlists that match the search.
    var hitster: [Playlist] {
        filtered(viewData.hitster)
    }

    /// The user's playlists that match the search.
    var library: [Playlist] {
        filtered(viewData.library)
    }

    /// Catalogue playlists found with the search term, every page loaded so far.
    var searchResults: [Playlist] {
        viewData.search?.playlists ?? []
    }

    /// `true` while the search may have more pages: the carousel shows a loader after its last playlist.
    var canLoadMoreResults: Bool {
        searchState == .loaded && viewData.search?.hasMore == true
    }

    /// Number shown next to the «Hitster» header.
    var hitsterCountText: String {
        hitster.count.formatted()
    }

    /// `true` when some section shows playlists.
    var hasPlaylists: Bool {
        !hitster.isEmpty || !library.isEmpty || !searchResults.isEmpty
    }

    /// `true` once every section on screen has loaded and none has playlists to show.
    var isEmpty: Bool {
        let states = isSearching ? [hitsterState, libraryState, searchState] : [hitsterState, libraryState]
        return states.allSatisfy { $0 == .loaded } && !hasPlaylists
    }

    /// Shown instead of the sections when `isEmpty`.
    var emptyMessage: String {
        isSearching
            ? String(localized: "playlistSelector.search.empty")
            : String(localized: "playlistSelector.empty \(viewData.providerName)")
    }

    /// Text under the playlist name: its curator, when the music service gives one.
    func subtitle(for playlist: Playlist) -> String {
        playlist.curatorName ?? ""
    }

    // MARK: Loading

    /// Loads «Hitster» and «Your playlists» at the same time. Each section shows its own result as soon as it
    /// arrives.
    func load() async {
        async let hitster: Void = loadHitster()
        async let library: Void = loadLibrary()
        _ = await (hitster, library)
    }

    func loadHitster() async {
        hitsterState = .loading
        do {
            viewData.hitster = try await hitsterPlayListUseCase.execute()
            hitsterState = .loaded
        } catch {
            hitsterState = .failed
        }
    }

    func loadLibrary() async {
        libraryState = .loading
        do {
            viewData.library = try await myPlaylistUseCase.execute()
            libraryState = .loaded
        } catch {
            libraryState = .failed
        }
    }

    /// Searches the term of «Search playlists» once the user stops typing. The view calls it on every change of
    /// `searchText` with `.task(id:)`, which cancels the search of the previous text.
    func search() async {
        let term = searchTerm
        guard !term.isEmpty else {
            resetSearch()
            return
        }
        do {
            try await Task.sleep(for: Self.searchDebounce)
        } catch {
            return
        }
        resetSearch()
        viewData.search = PlaylistSelectorViewData.SearchResults(term: term)
        searchState = .loading
        do {
            let page = try await searchByTermUseCase.execute(term: term, offset: 0)
            guard !Task.isCancelled else { return }
            viewData.search?.playlists = page.playlists
            viewData.search?.nextOffset = page.nextOffset
            viewData.search?.hasMore = page.hasMore
            searchState = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            searchState = .failed
        }
    }

    /// Loads the next page of the search. Called when the loader after the last result appears.
    func loadMoreResults() async {
        guard canLoadMoreResults, !isLoadingMoreResults, let search = viewData.search else { return }
        isLoadingMoreResults = true
        loadMoreResultsFailed = false
        defer { isLoadingMoreResults = false }
        do {
            let page = try await searchByTermUseCase.execute(term: search.term, offset: search.nextOffset)
            guard viewData.search?.term == search.term else { return }
            appendResults(page)
        } catch {
            guard viewData.search?.term == search.term else { return }
            loadMoreResultsFailed = true
        }
    }

    // MARK: Selection

    /// Message of the confirmation sheet: the curator and the music service (once if they match), then the question.
    func confirmationMessage(for playlist: Playlist) -> String {
        let details = [playlist.curatorName, viewData.providerName]
            .compactMap { $0 }
            .reduce(into: [String]()) { names, name in
                if !names.contains(name) { names.append(name) }
            }
            .joined(separator: " · ")
        return details + "\n" + String(localized: "playlistSelector.confirm.question")
    }

    /// A playlist was tapped: asks the user to confirm it.
    func didTap(_ playlist: Playlist) {
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

    // MARK: Private

    private func resetSearch() {
        viewData.search = nil
        searchState = .idle
        loadMoreResultsFailed = false
    }

    /// Adds a page to the results, skipping playlists already shown so every card keeps a unique identity.
    private func appendResults(_ page: PlaylistSelectorViewData.SearchPage) {
        let shown = Set(searchResults.map(\.id))
        viewData.search?.playlists += page.playlists.filter { !shown.contains($0.id) }
        viewData.search?.nextOffset = page.nextOffset
        viewData.search?.hasMore = page.hasMore
    }

    private func filtered(_ playlists: [Playlist]) -> [Playlist] {
        let query = searchTerm
        guard !query.isEmpty else { return playlists }
        return playlists.filter { $0.name.localizedStandardContains(query) }
    }
}
