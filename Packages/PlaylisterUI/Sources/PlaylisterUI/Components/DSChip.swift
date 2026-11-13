import SwiftUI

/// Small capsule with a short summary, e.g. the game mode at the top of the game («Clásico · 20 s»).
///
/// `tint-ink` text on `tint-fill`, footnote semibold. With an `action` it is a button: it shows a chevron, has a
/// 44 pt touch area and the press feedback of the round buttons; without one it is not interactive.
/// `.bingo` is for the Bingo mode («Bingo · Principiante»): it wears the round's category color on a tint of
/// that color, or `bubblegum` while no category has been drawn.
///
/// `text` is the label, so `.localized(_:)` localises it.
public struct DSChip: View, DSLocalizableText {
    public enum Style: Equatable, Sendable {
        case standard
        /// Bingo mode, colored with the round's category; `nil` falls back to `bubblegum`.
        case bingo(DSBingoCategory?)
    }

    public var text: String
    private let style: Style
    private let action: (@MainActor () -> Void)?

    public init(_ text: String = "", style: Style = .standard, action: (@MainActor () -> Void)? = nil) {
        self.text = text
        self.style = style
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                chip
                    .frame(minHeight: DSSpacing.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(DSPressStyle())
        } else {
            chip
        }
    }

    private var chip: some View {
        HStack(spacing: DSSpacing.space2) {
            Text(text)
                .lineLimit(1)
            if action != nil {
                Image(systemName: "chevron.down")
                    .font(DSFont.caption)
                    .accessibilityHidden(true)
            }
        }
        .font(DSFont.footnote.weight(.semibold))
        .foregroundStyle(ink)
        .padding(.horizontal, DSSpacing.space3)
        .padding(.vertical, DSSpacing.space2)
        .background(fill, in: Capsule())
    }

    private var ink: Color {
        switch style {
        case .standard: DSPalette.tintInk
        case .bingo(let category): category?.color ?? DSPalette.bubblegum
        }
    }

    private var fill: Color {
        switch style {
        case .standard: DSPalette.tintFill
        case .bingo(let category): (category?.color ?? DSPalette.bubblegum).opacity(0.16)
        }
    }
}

#Preview {
    VStack(spacing: DSSpacing.space3) {
        DSChip("Clásico · 20 s")
        DSChip("Bingo · Principiante", style: .bingo(nil))
        ForEach(DSBingoCategory.allCases) { category in
            DSChip("Bingo · Experto", style: .bingo(category))
        }
        DSChip("Clásico · 20 s") {}
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
