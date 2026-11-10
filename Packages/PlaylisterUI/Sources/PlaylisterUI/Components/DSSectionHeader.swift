import SwiftUI

/// Small-caps header above a group of rows (REPRODUCCIÓN, MODO DE JUEGO, CUENTA).
public struct DSSectionHeader: View, DSLocalizableText {
    public var text: String

    public init(_ text: String = "") {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(DSFont.caption)
            .tracking(DSTextStyle.caption.tracking)
            .textCase(.uppercase)
            .foregroundStyle(DSColor.textSecondary)
            .padding(.horizontal, DSSpacing.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DSSpacing.space2) {
        DSSectionHeader("Modo de juego")
        DSListGroup {
            DSListRow("Clásico", accessory: .checkmark)
            DSListRow("Bingo")
        }
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
