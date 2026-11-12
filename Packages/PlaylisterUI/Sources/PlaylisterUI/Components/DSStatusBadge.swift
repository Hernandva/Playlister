import SwiftUI

/// Capsule that shows the state of a connection, e.g. «Spotify conectado» at the top of Home.
///
/// - `spotify`: `spotify-green` dot and text on `spotify-green` at 16 %.
/// - `appleMusic`: `bubblegum` dot and `tint-ink` text on `tint-fill`.
///
/// With an `action` it is a button: it shows a chevron, has a 44 pt touch area and the press feedback of the
/// round buttons.
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
    private let action: (@MainActor () -> Void)?

    public init(_ text: String = "", style: Style, action: (@MainActor () -> Void)? = nil) {
        self.text = text
        self.style = style
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                badge
                    .frame(minHeight: DSSpacing.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(DSPressStyle())
        } else {
            badge
        }
    }

    private var badge: some View {
        HStack(spacing: DSSpacing.space2) {
            Circle()
                .fill(dotColor)
                .frame(width: Self.dotDiameter, height: Self.dotDiameter)
                .accessibilityHidden(true)
            Text(text)
                .font(DSFont.footnote.weight(.semibold))
                .foregroundStyle(inkColor)
            if action != nil {
                Image(systemName: "chevron.down")
                    .font(DSFont.caption)
                    .foregroundStyle(inkColor)
                    .accessibilityHidden(true)
            }
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
        DSStatusBadge("Spotify conectado", style: .spotify) {}
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
