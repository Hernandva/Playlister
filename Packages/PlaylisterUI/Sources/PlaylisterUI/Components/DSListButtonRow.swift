import SwiftUI

/// Row of a grouped list that runs an action: «Cerrar sesión». `.localized(_:)` localises the title.
/// `.plain` shows it in `bubblegum`, `.destructive` in `destructive`. It goes inside a `DSListGroup`.
public struct DSListButtonRow: View, DSLocalizableText {
    public enum Style: Sendable {
        case plain
        case destructive
    }

    public var text: String
    private let style: Style
    private let action: @MainActor () -> Void

    public init(_ text: String = "", style: Style = .plain, action: @escaping @MainActor () -> Void) {
        self.text = text
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(DSFont.body)
                .foregroundStyle(style == .destructive ? DSColor.destructive : DSPalette.bubblegum)
                .padding(.horizontal, DSSpacing.space4)
                .frame(maxWidth: .infinity, minHeight: DSSpacing.tapMin, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(DSPressStyle())
    }
}

#Preview {
    DSListGroup {
        DSListRow("Spotify", accessory: .value("Conectado"))
        DSListButtonRow("Cerrar sesión", style: .destructive) {}
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
