import SwiftUI

/// Small capsule with a short summary, e.g. the game mode at the top of the game («Clásico · 20 s»).
///
/// `tint-ink` text on `tint-fill`, footnote semibold. It is not interactive.
///
/// `text` is the label, so `.localized(_:)` localises it.
public struct DSChip: View, DSLocalizableText {
    public var text: String

    public init(_ text: String = "") {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(DSFont.footnote.weight(.semibold))
            .foregroundStyle(DSPalette.tintInk)
            .lineLimit(1)
            .padding(.horizontal, DSSpacing.space3)
            .padding(.vertical, DSSpacing.space2)
            .background(DSPalette.tintFill, in: Capsule())
    }
}

#Preview {
    VStack(spacing: DSSpacing.space3) {
        DSChip("Clásico · 20 s")
        DSChip("Bingo · Principiante")
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
