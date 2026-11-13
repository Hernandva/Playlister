import SwiftUI

/// Top of the game: a small-caps caption over the playlist name on the leading side, and a `DSChip` with the
/// mode on the trailing side. 44 pt tall at least; the name keeps to one line. With a `badgeAction` the chip is a
/// button, e.g. to open the game menu.
///
/// Strings are passed already localised.
public struct DSGameHeader: View {
    private let caption: String
    private let title: String
    private let badge: String
    private let badgeStyle: DSChip.Style
    private let badgeHint: String?
    private let badgeAction: (@MainActor () -> Void)?

    /// - Parameters:
    ///   - caption: Small caps label above the title («LISTA»).
    ///   - title: The playlist name.
    ///   - badge: Summary in the chip («Clásico · 20 s»).
    ///   - badgeStyle: Style of the chip: `.bingo(category)` in the Bingo mode, with the round's category.
    ///   - badgeHint: Accessibility hint of the chip when it is a button, already localised.
    ///   - badgeAction: Makes the chip a button that runs it.
    public init(
        caption: String,
        title: String,
        badge: String,
        badgeStyle: DSChip.Style = .standard,
        badgeHint: String? = nil,
        badgeAction: (@MainActor () -> Void)? = nil
    ) {
        self.caption = caption
        self.title = title
        self.badge = badge
        self.badgeStyle = badgeStyle
        self.badgeHint = badgeHint
        self.badgeAction = badgeAction
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space3) {
            VStack(alignment: .leading, spacing: DSSpacing.space1 / 2) {
                DSText(caption, style: .caption)
                DSText(title, style: .headline)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            DSChip(badge, style: badgeStyle, action: badgeAction)
                .accessibilityHint(badgeHint ?? "")
        }
        .frame(minHeight: DSSpacing.tapMin)
    }
}

#Preview {
    VStack(spacing: DSSpacing.space4) {
        DSGameHeader(caption: "LISTA", title: "Hitster España", badge: "Clásico · 20 s")
        DSGameHeader(
            caption: "LISTA",
            title: "Una lista con un nombre muy largo de verdad",
            badge: "Bingo · Experto",
            badgeStyle: .bingo(.cyan)
        )
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
