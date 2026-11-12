import SwiftUI

/// Capsule that shows the state of a connection, e.g. «Spotify conectado» at the top of Home.
///
/// - `spotify`: `spotify-green` dot and text on `spotify-green` at 16 %.
/// - `appleMusic`: `bubblegum` dot and `tint-ink` text on `tint-fill`.
///
/// `text` is the label, so `.localized(_:)` localises it.
public struct DSStatusBadge: View, DSLocalizableText {
    public enum Style: Sendable {
        case spotify
        case appleMusic
    }

    private static let dotDiameter: CGFloat = 8

    public var text: String
    private let style: Style

    public init(_ text: String = "", style: Style) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space2) {
            Circle()
                .fill(dotColor)
                .frame(width: Self.dotDiameter, height: Self.dotDiameter)
                .accessibilityHidden(true)
            Text(text)
                .font(DSFont.footnote.weight(.semibold))
                .foregroundStyle(inkColor)
        }
        .padding(.horizontal, DSSpacing.space3)
        .padding(.vertical, DSSpacing.space2)
        .background(fillColor, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var dotColor: Color {
        switch style {
        case .spotify: DSPalette.spotifyGreen
        case .appleMusic: DSPalette.bubblegum
        }
    }

    private var inkColor: Color {
        switch style {
        case .spotify: DSPalette.spotifyGreen
        case .appleMusic: DSPalette.tintInk
        }
    }

    private var fillColor: Color {
        switch style {
        case .spotify: DSPalette.spotifyGreen.opacity(0.16)
        case .appleMusic: DSPalette.tintFill
        }
    }
}

#Preview {
    VStack(spacing: DSSpacing.space3) {
        DSStatusBadge("Spotify conectado", style: .spotify)
        DSStatusBadge("Apple Music conectado", style: .appleMusic)
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
