import SwiftUI

/// Full-width button with the design-system styles applied.
public struct DSButton: View, DSLocalizableText {
    public enum Style: Sendable {
        case primary
        case secondary
        case destructive
    }

    public var text: String
    private let style: Style
    private let action: @MainActor () -> Void

    public init(_ text: String = "", style: Style = .primary, action: @escaping @MainActor () -> Void) {
        self.text = text
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(DSFont.bodyStrong)
                .frame(maxWidth: .infinity, minHeight: DSSpacing.tapMin)
                .padding(.horizontal, DSSpacing.medium)
        }
        .buttonStyle(DSButtonStyle(style: style))
    }
}

private struct DSButtonStyle: ButtonStyle {
    let style: DSButton.Style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch style {
        case .primary: DSColor.onAccent
        case .secondary: DSColor.accent
        case .destructive: DSColor.onDestructive
        }
    }

    private var background: Color {
        switch style {
        case .primary: DSColor.accent
        case .secondary: DSColor.fillSecondary
        case .destructive: DSColor.destructive
        }
    }
}

#Preview {
    VStack {
        DSButton("Primary") {}
        DSButton("Secondary", style: .secondary) {}
        DSButton("Delete", style: .destructive) {}
    }
    .padding()
}
