import PlaylisterUI
import SwiftUI

/// Long-press sheet of the selector: the songs of a playlist, 25 more each time the user scrolls to the last one,
/// and «Use this playlist», which asks to confirm it. Shown by `PlaylistSelectorView` with `.sheet(item:)`.
struct PlaylistSongsSheetView: View {
    let viewModel: PlaylistSongsViewModel
    let playlist: PlaylistSelectorViewData.Playlist
    /// Covers of the card, the custom ones included.
    let covers: [URL]
    /// «Use this playlist».
    let use: @MainActor () -> Void

    var body: some View {
        DSSongsSheet(
            title: playlist.name,
            subtitle: viewModel.summary,
            covers: covers,
            primaryAction: .init(String(localized: "playlistSelector.songs.use"), handler: use),
            closeAction: .init(String(localized: "playlistSelector.songs.close"), style: .plain) { viewModel.close() }
        ) {
            content
        }
        .task(id: playlist.id) { await viewModel.load() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .padding(.vertical, DSSpacing.space8)
        case .failed:
            VStack(spacing: DSSpacing.space2) {
                DSText(style: .footnote, color: DSColor.destructive)
                    .localized("playlistSelector.songs.error")
                DSButton(style: .plain) {
                    Task { await viewModel.load() }
                }
                .localized("playlistSelector.retry")
            }
            .padding(DSSpacing.space5)
        case .loaded:
            if viewModel.isEmpty {
                DSText(style: .subheadline, color: DSColor.textSecondary)
                    .localized("playlistSelector.songs.empty")
                    .padding(DSSpacing.space5)
            } else {
                ForEach(viewModel.songs) { song in
                    DSSongRow(
                        title: song.title,
                        artist: song.artist,
                        duration: viewModel.durationText(for: song),
                        cover: song.cover
                    )
                }
                loadMore
            }
        }
    }

    /// A loader after the last song asks for the next page; when it fails, a button tries again.
    @ViewBuilder private var loadMore: some View {
        if viewModel.loadMoreFailed {
            Button {
                Task { await viewModel.loadMore() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(DSIconButtonStyle(diameter: DSSpacing.tapMin))
            .accessibilityLabel(String(localized: "playlistSelector.songs.loadMore"))
            .padding(.vertical, DSSpacing.space3)
        } else if viewModel.canLoadMore {
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(height: DSSpacing.tapMin)
                .padding(.vertical, DSSpacing.space3)
                .task(id: viewModel.songs.count) { await viewModel.loadMore() }
        }
    }
}
