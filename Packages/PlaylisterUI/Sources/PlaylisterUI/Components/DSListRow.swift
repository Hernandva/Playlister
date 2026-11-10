import SwiftUI

/// Row of a grouped list: title, optional subtitle and an optional accessory. `.localized(_:)` localises the title.
/// Rows go inside a `DSListGroup`, which paints `surface-2` and the hairlines between them.
public struct DSListRow: View, DSLocalizableText {
    public enum Accessory: Sendable {
        case none
        /// Opens another screen.
        case chevron
        /// Selected option, in `bubblegum`.
        case checkmark
    }

    /// Minimum height of a row in a grouped list.
    public static let minHeight: CGFloat = 52

    public var text: String
    private let subtitle: String?
    private let accessory: Accessory

    public init(_ text: String = "", subtitle: String? = nil, accessory: Accessory = .none) {
        self.text = text
        self.subtitle = subtitle
        self.accessory = accessory
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space3) {
            VStack(alignment: .leading, spacing: DSSpacing.space1) {
                Text(text)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DSTypeScale.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            accessoryView
        }
        .padding(.horizontal, DSSpacing.space4)
        .padding(.vertical, DSSpacing.space3)
        .frame(minHeight: Self.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(accessory == .checkmark ? .isSelected : [])
    }

    @ViewBuilder private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .chevron:
            Image(systemName: "chevron.right")
                .font(DSFont.footnote.weight(.semibold))
                .foregroundStyle(DSPalette.textTertiary)
        case .checkmark:
            Image(systemName: "checkmark")
                .font(DSFont.body.weight(.semibold))
                .foregroundStyle(DSPalette.bubblegum)
        }
    }
}

#Preview {
    DSListGroup {
        DSListRow("Clásico", accessory: .checkmark)
        DSListRow("Bingo")
        DSListRow("Hitster España", subtitle: "312 canciones · Spotify", accessory: .chevron)
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
