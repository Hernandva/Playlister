import Foundation
import Observation
import PlaylisterData

/// State of the long-press sheet of the selector: the songs of one playlist, loaded 25 at a time.
/// `PlaylistSelectorViewModel` owns it and opens it with `open(_:)`.
@MainActor
@Observable
final class PlaylistSongsViewModel {
    typealias Playlist = PlaylistSelectorViewData.Playlist
    typealias Song = PlaylistSelectorViewData.Song
    typealias SectionState = PlaylistSelectorViewModel.SectionState

    /// Playlist whose songs sheet is shown, or `nil` when the sheet is closed.
    var playlist: Playlist?
    /// State of the first page.
    private(set) var state: SectionState = .idle
    /// `true` while the next page loads.
    private(set) var isLoadingMore = false
    /// `true` when the next page could not load: the list offers to try again.
    private(set) var loadMoreFailed = false
    /// Every page of songs loaded so far, the `playlistSongs` of the selector's ViewData.
    private(set) var playlistSongs: PlaylistSelectorViewData.PlaylistSongs?

    private let useCase: any FetchSongsFromPlaylistUseCaseProtocol
    private let provider: MusicProvider

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: PlaylistSelectorDependencies) {
        self.provider = dependencies.resolveProvider()
        self.useCase = dependencies.resolveFetchSongsFromPlaylistUseCase()
    }

    /// Songs loaded so far.
    var songs: [Song] {
        playlistSongs?.songs ?? []
    }

    /// `true` while the playlist may have more pages: the list shows a loader after its last song.
    var canLoadMore: Bool {
        state == .loaded && playlistSongs?.hasMore == true
    }

    /// `true` once the first page loaded without songs.
    var isEmpty: Bool {
        state == .loaded && songs.isEmpty
    }

    /// Text under the name, e.g. «312 canciones · 19 h 40 min». The count shows once it is known, from the music
    /// service or because every song has loaded, and the length once every song has loaded. Until then, the curator.
    var summary: String {
        let parts = [countText, totalDurationText].compactMap { $0 }
        return parts.isEmpty ? playlist?.curatorName ?? "" : parts.joined(separator: " · ")
    }

    /// Length of a song as «m:ss», or `nil` when the music service does not give it.
    func durationText(for song: Song) -> String? {
        song.duration.map { Duration.seconds($0).formatted(.time(pattern: .minuteSecond)) }
    }

    // MARK: Actions

    /// Opens the sheet of `playlist` with no songs yet; the sheet loads them with `load()`.
    func open(_ playlist: Playlist) {
        self.playlist = playlist
        playlistSongs = PlaylistSelectorViewData.PlaylistSongs(playlistID: playlist.id)
        state = .idle
        isLoadingMore = false
        loadMoreFailed = false
    }

    /// Closes the sheet.
    func close() {
        playlist = nil
    }

    /// Loads the first page. Called when the sheet appears and by «Try again».
    func load() async {
        guard let playlistID = playlistSongs?.playlistID else { return }
        state = .loading
        do {
            let page = try await useCase.execute(playlistID: playlistID, provider: provider, offset: 0)
            guard playlistSongs?.playlistID == playlistID else { return }
            playlistSongs = PlaylistSelectorViewData.PlaylistSongs(playlistID: playlistID)
            append(page)
            state = .loaded
        } catch {
            guard playlistSongs?.playlistID == playlistID, !Task.isCancelled else { return }
            state = .failed
        }
    }

    /// Loads the next page. Called when the loader after the last song appears.
    func loadMore() async {
        guard canLoadMore, !isLoadingMore, let current = playlistSongs else { return }
        isLoadingMore = true
        loadMoreFailed = false
        defer { isLoadingMore = false }
        do {
            let page = try await useCase.execute(
                playlistID: current.playlistID,
                provider: provider,
                offset: current.nextOffset
            )
            guard playlistSongs?.playlistID == current.playlistID else { return }
            append(page)
        } catch {
            guard playlistSongs?.playlistID == current.playlistID else { return }
            loadMoreFailed = true
        }
    }

    // MARK: Private

    /// Songs of the whole playlist, when the music service said so or every song has loaded.
    private var totalCount: Int? {
        guard let playlistSongs, state == .loaded else { return nil }
        return playlistSongs.total ?? (playlistSongs.hasMore ? nil : playlistSongs.songs.count)
    }

    private var countText: String? {
        totalCount.map { String(localized: "playlistSelector.songs.count \($0)") }
    }

    /// Length of the whole playlist, once every song has loaded and at least one has a length.
    private var totalDurationText: String? {
        guard let playlistSongs, state == .loaded, !playlistSongs.hasMore else { return nil }
        let seconds = playlistSongs.songs.compactMap(\.duration).reduce(0, +)
        guard seconds > 0 else { return nil }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    /// Adds a page, skipping songs already shown so every row keeps a unique identity.
    /// Works on a copy and assigns it once: reading `playlistSongs` while writing it through `?.` is a simultaneous
    /// access, and one assignment also notifies the view once.
    private func append(_ page: PlaylistSelectorViewData.SongsPage) {
        guard var updated = playlistSongs else { return }
        let shown = Set(updated.songs.map(\.id))
        updated.songs += page.songs.filter { !shown.contains($0.id) }
        updated.nextOffset = page.nextOffset
        updated.hasMore = page.hasMore
        updated.total = page.total ?? updated.total
        playlistSongs = updated
    }
}
