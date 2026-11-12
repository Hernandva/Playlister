import PlaylisterUI
import SwiftUI

/// One section of the playlist selector: its header, then its own loading indicator, an error with «Try again»,
/// or a carousel of playlist cards. It hides itself once loaded with no playlists to show.
/// `tail` goes after the last card, e.g. the loader that asks for the next page of the search.
struct PlaylistSelectorSection<Tail: View>: View {
    typealias Playlist = PlaylistSelectorViewData.Playlist

    let titleKey: String
    /// Text at the end of the header, e.g. the number of playlists.
    var count: String?
    let state: PlaylistSelectorViewModel.SectionState
    let playlists: [Playlist]
    let cardSize: CGFloat
    let subtitle: (Playlist) -> String
    let onSelect: @MainActor (Playlist) -> Void
    let onRetry: @MainActor @Sendable () -> Void
    @ViewBuilder let tail: () -> Tail

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                header
                content
            }
        }
    }

    private var isVisible: Bool {
        switch state {
        case .idle: false
        case .loading, .failed: true
        case .loaded: !playlists.isEmpty
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            DSText(style: .sectionTitle)
                .localized(titleKey)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let count, state == .loaded {
                DSText(count, style: .subheadline, color: DSColor.textSecondary)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: cardSize)
        case .failed:
            VStack(alignment: .leading, spacing: DSSpacing.space2) {
                DSText(style: .footnote, color: DSColor.destructive)
                    .localized("playlistSelector.section.error")
                DSButton(style: .plain, action: onRetry)
                    .localized("playlistSelector.retry")
            }
        case .loaded:
            carousel
        }
    }

    /// Horizontal row of playlist cards that runs to the screen edges.
    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: DSSpacing.space3) {
                ForEach(playlists) { playlist in
                    Button {
                        onSelect(playlist)
                    } label: {
                        DSPlaylistCard(
                            playlist.name,
                            subtitle: subtitle(playlist),
                            covers: playlist.covers,
                            size: cardSize
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(String(localized: "playlistSelector.card.hint"))
                }
                tail()
            }
            .padding(.horizontal, DSSpacing.space4)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -DSSpacing.space4)
    }
}
