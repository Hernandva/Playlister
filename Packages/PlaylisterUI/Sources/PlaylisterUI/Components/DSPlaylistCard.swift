import SwiftUI

/// Playlist card: a 2×2 mosaic of up to 4 covers from different albums, the name and the song count.
///
/// - `size`: 200 pt in carousels, 150 pt in «Tus listas», 112–136 pt in Home and sheets.
/// - With fewer than 4 covers, the first one fills the square.
/// - Place cards in a `ScrollView(.horizontal)` with 14 pt between them. Tap opens the confirm sheet,
///   a long press the songs sheet (handled by the caller).
///
/// `text` is the playlist name, so `.localized(_:)` localises it.
public struct DSPlaylistCard: View, DSLocalizableText {
    public var text: String
    private let subtitle: String
    private let covers: [URL]
    private let size: CGFloat

    public init(_ name: String = "", subtitle: String, covers: [URL], size: CGFloat = 200) {
        self.text = name
        self.subtitle = subtitle
        self.covers = covers
        self.size = size
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space2) {
            DSCoverMosaic(covers: covers)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusCard, style: .continuous))
                .dsShadow(.card)
            VStack(alignment: .leading, spacing: DSSpacing.space1) {
                Text(text)
                    .font(DSFont.headline)
                    .foregroundStyle(DSColor.textPrimary)
                Text(subtitle)
                    .font(DSTypeScale.subheadline)
                    .foregroundStyle(DSColor.textSecondary)
            }
            .lineLimit(1)
        }
        .frame(width: size, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// 2×2 mosaic of album covers with 2 pt gaps, or one cover filling the square.
public struct DSCoverMosaic: View {
    private static let gap: CGFloat = 2
    private let covers: [URL]

    public init(covers: [URL]) {
        self.covers = covers
    }

    public var body: some View {
        Group {
            if covers.count >= 4 {
                VStack(spacing: Self.gap) {
                    HStack(spacing: Self.gap) {
                        DSCoverImage(url: covers[0])
                        DSCoverImage(url: covers[1])
                    }
                    HStack(spacing: Self.gap) {
                        DSCoverImage(url: covers[2])
                        DSCoverImage(url: covers[3])
                    }
                }
            } else {
                DSCoverImage(url: covers.first)
            }
        }
        .background(DSPalette.surface2)
        .accessibilityHidden(true)
    }
}

/// Album cover that fills its frame, on `surface-2` while it loads or when there is none.
public struct DSCoverImage: View {
    private let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        Color.clear
            .overlay {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        ZStack {
                            DSPalette.surface2
                            Image(systemName: "music.note")
                                .font(DSFont.title)
                                .foregroundStyle(DSPalette.textTertiary)
                        }
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 14) {
            DSPlaylistCard("Hitster España", subtitle: "312 canciones", covers: [])
            DSPlaylistCard("Hitster 80s", subtitle: "95 canciones", covers: [], size: 150)
        }
        .padding(DSSpacing.space4)
    }
    .background(DSColor.background)
}
