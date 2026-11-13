import SwiftUI

/// The look of the five Bingo categories: each one's fixed color. The colors are light, so text on them is always
/// `bg-night`, never white.
///
/// Only the look lives here. Which levels exist and what each category is called come from the app's data (the
/// Settings repository), and components that show a category's name receive it already localised.
public enum DSBingoCategory: Int, CaseIterable, Identifiable, Sendable {
    case pink
    case yellow
    case cyan
    case green
    case orange

    public var id: Int { rawValue }

    public var color: Color {
        switch self {
        case .pink: DSPalette.bingoPink
        case .yellow: DSPalette.bingoYellow
        case .cyan: DSPalette.bingoCyan
        case .green: DSPalette.bingoGreen
        case .orange: DSPalette.bingoOrange
        }
    }

    /// Text and icons on `color`.
    public var ink: Color { DSColor.background }
}

/// Settings row of a Bingo category: color square and its name, already localised. It goes inside a `DSListGroup`.
public struct DSBingoCategoryRow: View {
    private static let swatch: CGFloat = 28
    private let category: DSBingoCategory
    private let title: String

    public init(category: DSBingoCategory, title: String) {
        self.category = category
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space3) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(category.color)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                }
                .frame(width: Self.swatch, height: Self.swatch)
                .accessibilityHidden(true)
            Text(title)
                .font(DSFont.body)
                .foregroundStyle(DSColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DSSpacing.space4)
        .frame(minHeight: DSListRow.minHeight)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DSListGroup {
        DSBingoCategoryRow(category: .pink, title: "¿Nacional o internacional?")
        DSBingoCategoryRow(category: .yellow, title: "¿Antes del 2000?")
        DSBingoCategoryRow(category: .cyan, title: "± 4 años")
        DSBingoCategoryRow(category: .green, title: "Década")
        DSBingoCategoryRow(category: .orange, title: "Solista o grupo")
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
