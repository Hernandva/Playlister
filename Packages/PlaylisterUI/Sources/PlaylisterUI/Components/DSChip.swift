import SwiftUI

/// Small capsule with a short summary, e.g. the game mode at the top of the game («Clásico · 20 s»).
///
/// `tint-ink` text on `tint-fill`, footnote semibold. It is not interactive.
/// `.bingo` wears `bubblegum` on a `bubblegum` tint, for the Bingo mode («Bingo · Principiante»).
///
/// `text` is the label, so `.localized(_:)` localises it.
public struct DSChip: View, DSLocalizableText {
    public enum Style: Sendable {
        case standard
        case bingo
    }

    public var text: String
    private let style: Style

    public init(_ text: String = "", style: Style = .standard) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        Text(text)
            .font(DSFont.footnote.weight(.semibold))
            .foregroundStyle(style == .bingo ? DSPalette.bubblegum : DSPalette.tintInk)
            .lineLimit(1)
            .padding(.horizontal, DSSpacing.space3)
            .padding(.vertical, DSSpacing.space2)
            .background(style == .bingo ? DSPalette.bubblegum.opacity(0.16) : DSPalette.tintFill, in: Capsule())
    }
}

#Preview {
    VStack(spacing: DSSpacing.space3) {
        DSChip("Clásico · 20 s")
        DSChip("Bingo · Principiante", style: .bingo)
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
