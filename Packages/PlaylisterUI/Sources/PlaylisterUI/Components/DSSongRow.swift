import SwiftUI

/// Row of a song list: a 48 pt cover, the title, the artist and the length, with a `hairline` under the texts.
/// Texts are passed already localised; `duration` is formatted by the caller, e.g. «3:48».
public struct DSSongRow: View {
    /// Side of the cover.
    public static let coverSize: CGFloat = 48

    private let title: String
    private let artist: String
    private let duration: String?
    private let cover: URL?

    /// - Parameter cover: Album artwork, or `nil` to show the placeholder.
    public init(title: String, artist: String, duration: String? = nil, cover: URL?) {
        self.title = title
        self.artist = artist
        self.duration = duration
        self.cover = cover
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space3) {
            DSCoverImage(url: cover)
                .frame(width: Self.coverSize, height: Self.coverSize)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusControl, style: .continuous))
            HStack(spacing: DSSpacing.space3) {
                VStack(alignment: .leading, spacing: DSSpacing.space1 / 2) {
                    Text(title)
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(artist)
                        .font(DSTypeScale.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                if let duration {
                    Text(duration)
                        .font(DSTypeScale.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(DSPalette.textTertiary)
                }
            }
            .padding(.bottom, DSSpacing.space2)
            .overlay(alignment: .bottom) {
                DSColor.separator.frame(height: 1)
            }
        }
        .padding(.horizontal, DSSpacing.space5)
        .padding(.vertical, DSSpacing.space2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        DSSongRow(title: "Bohemian Rhapsody", artist: "Queen", duration: "5:55", cover: nil)
        DSSongRow(title: "Despacito", artist: "Luis Fonsi, Daddy Yankee", duration: "3:48", cover: nil)
        DSSongRow(title: "La Bamba", artist: "Ritchie Valens", cover: nil)
    }
    .background(DSColor.background)
}
