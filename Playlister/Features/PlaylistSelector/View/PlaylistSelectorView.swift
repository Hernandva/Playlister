import PlaylisterData
import PlaylisterUI
import SwiftUI

/// Playlist selector: a search field, the «Hitster» playlists of the catalogue and the user's playlists.
/// Cards show only the playlist's artwork, name and curator. Tapping one asks to confirm it; once confirmed,
/// ProviderStarter shows it and the selector closes.
struct PlaylistSelectorView: View {
    /// Card sides of the design system: 200 pt in the recommended carousel, 150 pt in «Your playlists».
    private static let recommendedCardSize: CGFloat = 200
    private static let libraryCardSize: CGFloat = 150

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
        .sheet(item: $viewModel.pendingPlaylist, onDismiss: closeIfSelected) { playlist in
            confirmationSheet(for: playlist)
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(maxWidth: .infinity)
        case .loaded:
            loadedContent
        case .failed(let message):
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                DSText(message, style: .footnote, color: DSColor.destructive)
                DSButton(style: .plain) {
                    Task { await viewModel.load() }
                }
                .localized("playlistSelector.retry")
            }
        }
    }

    @ViewBuilder private var loadedContent: some View {
        if viewModel.isSearching, viewModel.recommended.isEmpty, viewModel.library.isEmpty {
            DSText(style: .subheadline, color: DSColor.textSecondary)
                .localized("playlistSelector.search.empty")
        } else {
            recommendedSection
            librarySection
            DSText(style: .footnote, color: DSColor.textSecondary)
                .localized("playlistSelector.hint")
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var recommendedSection: some View {
        if !viewModel.recommended.isEmpty || !viewModel.isSearching {
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                HStack(alignment: .firstTextBaseline) {
                    DSText(style: .sectionTitle)
                        .localized("playlistSelector.recommended.header")
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    DSText(viewModel.recommendedCountText, style: .subheadline, color: DSColor.textSecondary)
                }
                if viewModel.recommended.isEmpty {
                    DSText(style: .subheadline, color: DSColor.textSecondary)
                        .localized("playlistSelector.recommended.empty")
                } else {
                    carousel(viewModel.recommended, cardSize: Self.recommendedCardSize)
                }
            }
        }
    }

    @ViewBuilder private var librarySection: some View {
        if !viewModel.library.isEmpty || !viewModel.isSearching {
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                DSText(style: .sectionTitle)
                    .localized("playlistSelector.library.header")
                    .accessibilityAddTraits(.isHeader)
                if viewModel.library.isEmpty {
                    DSText(viewModel.emptyLibraryMessage, style: .subheadline, color: DSColor.textSecondary)
                } else {
                    carousel(viewModel.library, cardSize: Self.libraryCardSize)
                }
            }
        }
    }

    /// Horizontal row of playlist cards that runs to the screen edges.
    private func carousel(_ playlists: [PlaylistSelectorViewData.Playlist], cardSize: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: DSSpacing.space3) {
                ForEach(playlists) { playlist in
                    Button {
                        viewModel.didTap(playlist)
                    } label: {
                        DSPlaylistCard(
                            playlist.name,
                            subtitle: viewModel.subtitle(for: playlist),
                            covers: playlist.covers,
                            size: cardSize
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(String(localized: "playlistSelector.card.hint"))
                }
            }
            .padding(.horizontal, DSSpacing.space4)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -DSSpacing.space4)
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
