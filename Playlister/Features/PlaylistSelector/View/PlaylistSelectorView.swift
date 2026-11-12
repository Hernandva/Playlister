import PlaylisterData
import PlaylisterUI
import SwiftUI

/// Playlist selector: a search field, the playlists found with it, the «Hitster» playlists and the user's playlists.
/// Every section loads on its own, in parallel, and disappears when it has no playlists. The search results load
/// 25 more each time the user scrolls to the last one. A playlist without artwork shows the covers of four random
/// songs. Tapping a playlist asks to confirm it; once confirmed,
/// ProviderStarter shows it and the selector closes.
struct PlaylistSelectorView: View {
    /// Card sides of the design system: 200 pt for «Hitster», 150 pt for the search and «Your playlists».
    private static let hitsterCardSize: CGFloat = 200
    private static let listCardSize: CGFloat = 150

    @State private var viewModel: PlaylistSelectorViewModel
    @Environment(\.dismiss) private var dismiss

    /// Receives only the container and resolves the view model from it.
    init(dependencies: PlaylistSelectorDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle)
                .localized("playlistSelector.title")
                .accessibilityAddTraits(.isHeader)
            DSTextField(value: $viewModel.searchText, systemImage: "magnifyingglass")
                .localized("playlistSelector.search")
            content
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .task(id: viewModel.searchText) { await viewModel.search() }
        .sheet(item: $viewModel.pendingPlaylist, onDismiss: closeIfSelected) { playlist in
            confirmationSheet(for: playlist)
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isEmpty {
            DSText(viewModel.emptyMessage, style: .subheadline, color: DSColor.textSecondary)
        } else {
            if viewModel.isSearching {
                searchSection
            }
            hitsterSection
            librarySection
            if viewModel.hasPlaylists {
                DSText(style: .footnote, color: DSColor.textSecondary)
                    .localized("playlistSelector.hint")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Catalogue playlists found with the search term. A loader after the last one asks for the next page.
    private var searchSection: some View {
        DSPlaylistSection(
            texts(title: "playlistSelector.search.header"),
            state: DSSectionState(viewModel.searchState),
            items: items(viewModel.searchResults),
            cardSize: Self.listCardSize,
            actions: actions(for: viewModel.searchResults) { await viewModel.search() }
        ) {
            loadMoreResults
        }
    }

    @ViewBuilder private var loadMoreResults: some View {
        if viewModel.loadMoreResultsFailed {
            Button {
                Task { await viewModel.loadMoreResults() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(DSIconButtonStyle(diameter: DSSpacing.tapMin))
            .accessibilityLabel(String(localized: "playlistSelector.search.loadMore"))
            .frame(height: Self.listCardSize)
        } else if viewModel.canLoadMoreResults {
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(width: DSSpacing.tapMin, height: Self.listCardSize)
                .task(id: viewModel.searchResults.count) { await viewModel.loadMoreResults() }
        }
    }

    private var hitsterSection: some View {
        DSPlaylistSection(
            texts(title: "playlistSelector.recommended.header", count: viewModel.hitsterCountText),
            state: DSSectionState(viewModel.hitsterState),
            items: items(viewModel.hitster),
            cardSize: Self.hitsterCardSize,
            actions: actions(for: viewModel.hitster) { await viewModel.loadHitster() }
        )
    }

    private var librarySection: some View {
        DSPlaylistSection(
            texts(title: "playlistSelector.library.header"),
            state: DSSectionState(viewModel.libraryState),
            items: items(viewModel.library),
            cardSize: Self.listCardSize,
            actions: actions(for: viewModel.library) { await viewModel.loadLibrary() }
        )
    }

    // MARK: Sections

    /// Localised texts of a section: its title, the error and «Try again» shared by every section.
    private func texts(title key: String.LocalizationValue, count: String? = nil) -> DSPlaylistSectionTexts {
        DSPlaylistSectionTexts(
            title: String(localized: key),
            count: count,
            errorMessage: String(localized: "playlistSelector.section.error"),
            retry: String(localized: "playlistSelector.retry"),
            cardHint: String(localized: "playlistSelector.card.hint")
        )
    }

    /// What each card shows: the name, the curator and the covers, custom ones included.
    private func items(_ playlists: [PlaylistSelectorViewData.Playlist]) -> [DSPlaylistSectionItem] {
        playlists.map { playlist in
            DSPlaylistSectionItem(
                id: playlist.id,
                name: playlist.name,
                subtitle: viewModel.subtitle(for: playlist),
                covers: viewModel.covers(for: playlist)
            )
        }
    }

    /// Tapping a card asks to confirm its playlist, a card on screen loads its custom artwork when it needs one,
    /// and «Try again» runs `retry`.
    private func actions(
        for playlists: [PlaylistSelectorViewData.Playlist],
        retry: @escaping @MainActor @Sendable () async -> Void
    ) -> DSPlaylistSectionActions {
        let viewModel = viewModel
        let playlistsByID = [String: PlaylistSelectorViewData.Playlist](
            playlists.map { ($0.id, $0) }
        ) { first, _ in first }
        return DSPlaylistSectionActions(
            select: { item in
                if let playlist = playlistsByID[item.id] {
                    viewModel.didTap(playlist)
                }
            },
            retry: { Task { await retry() } },
            cardAppear: { item in
                if let playlist = playlistsByID[item.id] {
                    await viewModel.loadCustomArtworkIfNeeded(for: playlist)
                }
            }
        )
    }

    private func confirmationSheet(for playlist: PlaylistSelectorViewData.Playlist) -> some View {
        DSBottomSheet(
            title: playlist.name,
            message: viewModel.confirmationMessage(for: playlist),
            primaryAction: .init(String(localized: "playlistSelector.confirm.select")) {
                viewModel.confirmSelection()
            },
            secondaryAction: .init(String(localized: "playlistSelector.confirm.cancel"), style: .plain) {
                viewModel.cancelSelection()
            }
        )
    }

    /// Goes back to ProviderStarter once the sheet has closed, so both animations do not run at the same time.
    private func closeIfSelected() {
        if viewModel.wantsToClose {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistSelectorCoordinator(provider: .appleMusic, selectPlaylist: { _ in }).start()
    }
}

private extension DSSectionState {
    /// The design system's state of a section of the view model.
    init(_ state: PlaylistSelectorViewModel.SectionState) {
        switch state {
        case .idle: self = .idle
        case .loading: self = .loading
        case .loaded: self = .loaded
        case .failed: self = .failed
        }
    }
}
