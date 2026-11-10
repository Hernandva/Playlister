import SwiftUI

/// Difficulty of the Bingo mode. It changes the name of each category.
public enum DSBingoLevel: Sendable, CaseIterable {
    case beginner
    case expert
}

/// The five Bingo categories, always in this order, each with its fixed color.
/// The colors are light, so text on them is always `bg-night`, never white.
///
/// Names are looked up in the app's `Localizable.xcstrings` (`bingo.category.<color>.<beginner|expert>`,
/// e.g. `bingo.category.pink.beginner`) with the Spanish names as default values.
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

    /// Localised name of the category for `level`.
    public func title(for level: DSBingoLevel) -> String {
        let suffix = level == .beginner ? "beginner" : "expert"
        let fallback = level == .beginner ? defaultNames.beginner : defaultNames.expert
        return Bundle.main.localizedString(forKey: "bingo.category.\(self).\(suffix)", value: fallback, table: nil)
    }

    /// Names from the BingoCategory guide of the design system.
    private var defaultNames: (beginner: String, expert: String) {
        switch self {
        case .pink: ("Grupo o solista", "Título de la canción")
        case .yellow: ("¿Antes del 2000?", "Año exacto")
        case .cyan: ("± 4 años", "Nombre del grupo o cantante")
        case .green: ("Década", "Década")
        case .orange: ("± 2 años", "± 3 años")
        }
    }
}

/// Settings row of a Bingo category: color square, name and switch. Off categories show at 45 % opacity.
/// It goes inside a `DSListGroup`.
public struct DSBingoCategoryRow: View {
    private static let swatch: CGFloat = 28
    private let category: DSBingoCategory
    private let level: DSBingoLevel
    @Binding private var isOn: Bool

    public init(category: DSBingoCategory, level: DSBingoLevel, isOn: Binding<Bool>) {
        self.category = category
        self.level = level
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: DSSpacing.space3) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(category.color)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                    }
                    .frame(width: Self.swatch, height: Self.swatch)
                    .accessibilityHidden(true)
                Text(category.title(for: level))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.textPrimary)
            }
            .opacity(isOn ? 1 : 0.45)
        }
        .toggleStyle(DSSwitchToggleStyle())
        .padding(.horizontal, DSSpacing.space4)
        .frame(minHeight: DSListRow.minHeight)
    }
}

#Preview {
    @Previewable @State var enabled: Set<DSBingoCategory> = Set(DSBingoCategory.allCases)
    DSListGroup {
        ForEach(DSBingoCategory.allCases) { category in
            DSBingoCategoryRow(category: category, level: .beginner, isOn: Binding(
                get: { enabled.contains(category) },
                set: { isOn in
                    if isOn { enabled.insert(category) } else { enabled.remove(category) }
                }
            ))
        }
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
