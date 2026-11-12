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
        PlaylistSelectorSection(
            titleKey: "playlistSelector.search.header",
            state: viewModel.searchState,
            playlists: viewModel.searchResults,
            cardSize: Self.listCardSize,
            subtitle: viewModel.subtitle(for:),
            covers: viewModel.covers(for:),
            onCardAppear: { await viewModel.loadCustomArtworkIfNeeded(for: $0) },
            onSelect: viewModel.didTap,
            onRetry: { Task { await viewModel.search() } },
            tail: { loadMoreResults }
        )
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
        PlaylistSelectorSection(
            titleKey: "playlistSelector.recommended.header",
            count: viewModel.hitsterCountText,
            state: viewModel.hitsterState,
            playlists: viewModel.hitster,
            cardSize: Self.hitsterCardSize,
            subtitle: viewModel.subtitle(for:),
            covers: viewModel.covers(for:),
            onCardAppear: { await viewModel.loadCustomArtworkIfNeeded(for: $0) },
            onSelect: viewModel.didTap,
            onRetry: { Task { await viewModel.loadHitster() } },
            tail: { EmptyView() }
        )
    }

    private var librarySection: some View {
        PlaylistSelectorSection(
            titleKey: "playlistSelector.library.header",
            state: viewModel.libraryState,
            playlists: viewModel.library,
            cardSize: Self.listCardSize,
            subtitle: viewModel.subtitle(for:),
            covers: viewModel.covers(for:),
            onCardAppear: { await viewModel.loadCustomArtworkIfNeeded(for: $0) },
            onSelect: viewModel.didTap,
            onRetry: { Task { await viewModel.loadLibrary() } },
            tail: { EmptyView() }
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
