import SwiftUI

/// Large bottom sheet with the songs of a playlist: a 64 pt cover mosaic, the name, a summary (e.g. «312 canciones ·
/// 19 h 40 min») and a close button, a `hairline`, the scrolling `content` and a `.primary` button pinned at the bottom.
///
/// Present it from `.sheet(item:)`. Put `DSSongRow`s, a loader or a message in `content`; it already scrolls:
///
///     .sheet(item: $viewModel.songsPlaylist) { playlist in
///         DSSongsSheet(
///             title: playlist.name,
///             subtitle: viewModel.songsSummary,
///             covers: viewModel.covers(for: playlist),
///             primaryAction: .init(String(localized: "songs.use")) { viewModel.useSongsPlaylist() },
///             closeAction: .init(String(localized: "common.close")) { viewModel.closeSongs() }
///         ) {
///             ForEach(viewModel.songs) { DSSongRow(title: $0.title, artist: $0.artist, cover: $0.cover) }
///         }
///     }
///
/// Texts are passed already localised. The title of `closeAction` is the accessibility label of the close button.
public struct DSSongsSheet<Content: View>: View {
    /// Side of the cover mosaic of the header.
    private static var mosaicSize: CGFloat { 64 }
    /// Diameter of the close button; its touch area is `DSSpacing.tapMin`.
    private static var closeDiameter: CGFloat { 30 }

    private let title: String
    private let subtitle: String
    private let covers: [URL]
    private let primaryAction: DSBottomSheet.Action
    private let closeAction: DSBottomSheet.Action
    private let content: Content

    public init(
        title: String,
        subtitle: String,
        covers: [URL],
        primaryAction: DSBottomSheet.Action,
        closeAction: DSBottomSheet.Action,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.covers = covers
        self.primaryAction = primaryAction
        self.closeAction = closeAction
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            DSColor.separator
                .frame(height: 1)
                .padding(.horizontal, DSSpacing.space5)
            ScrollView {
                LazyVStack(spacing: 0) {
                    content
                }
                .padding(.vertical, DSSpacing.space1)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DSButton(primaryAction.title, style: primaryAction.style, action: primaryAction.handler)
                .padding(.horizontal, DSSpacing.space5)
                .padding(.top, DSSpacing.space3)
                .padding(.bottom, DSSpacing.space2)
                .background {
                    LinearGradient(
                        colors: [DSColor.surface.opacity(0), DSColor.surface],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DSRadius.radiusSheet)
        .presentationBackground { DSAuraBackground() }
        .tint(DSPalette.bubblegum)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: DSSpacing.space3) {
            DSCoverMosaic(covers: covers)
                .frame(width: Self.mosaicSize, height: Self.mosaicSize)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusControl, style: .continuous))
            VStack(alignment: .leading, spacing: DSSpacing.space1 / 2) {
                DSText(title, style: .title)
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)
                if !subtitle.isEmpty {
                    DSText(subtitle, style: .subheadline, color: DSColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: closeAction.handler) {
                Image(systemName: "xmark")
            }
            .buttonStyle(DSIconButtonStyle(diameter: Self.closeDiameter))
            .frame(width: DSSpacing.tapMin, height: DSSpacing.tapMin)
            .contentShape(Rectangle())
            .accessibilityLabel(closeAction.title)
        }
        .padding(.horizontal, DSSpacing.space5)
        .padding(.top, DSSpacing.space6)
        .padding(.bottom, DSSpacing.space4)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DSSongsSheet(
                title: "Hitster España",
                subtitle: "312 canciones · 19 h 40 min",
                covers: [],
                primaryAction: .init("Usar esta lista") {},
                closeAction: .init("Cerrar") {}
            ) {
                ForEach(["Bohemian Rhapsody", "Billie Jean", "Mediterráneo", "Dancing Queen"], id: \.self) { title in
                    DSSongRow(title: title, artist: "Artista", duration: "3:48", cover: nil)
                }
            }
        }
        .background { DSAuraBackground() }
}
