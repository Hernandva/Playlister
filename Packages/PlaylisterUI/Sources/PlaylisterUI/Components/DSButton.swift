import SwiftUI

/// Button of the design system.
///
/// - `primary`: 52 pt capsule with the animated primary gradient and `shadow-glow`. One per screen.
/// - `secondary`: capsule with `tint-fill` and `tint-ink` text, for alternatives.
/// - `plain`: no background, `bubblegum` text (Cancelar, going back).
/// - `destructive`: plain with `destructive` text (Cerrar sesión).
/// - `spotify` / `appleMusic`: login capsules. The official logo is added by the caller.
///
/// `trailingSystemImage` adds a symbol after the text, e.g. `chevron.right` on «Continuar»; it is not read by
/// VoiceOver.
public struct DSButton: View, DSLocalizableText {
    public enum Style: Sendable {
        case primary
        case secondary
        case plain
        case destructive
        case spotify
        case appleMusic
    }

    public var text: String
    private let style: Style
    private let trailingSystemImage: String?
    private let action: @MainActor () -> Void

    public init(
        _ text: String = "",
        style: Style = .primary,
        trailingSystemImage: String? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.text = text
        self.style = style
        self.trailingSystemImage = trailingSystemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.space2) {
                Text(text)
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(DSButtonStyle(style: style))
    }
}

/// Button style behind `DSButton`. Use it directly for buttons with a custom label.
public struct DSButtonStyle: ButtonStyle {
    /// Height of the capsule buttons.
    public static let capsuleHeight: CGFloat = 52
    /// Text on the login buttons (#0A0A0A), as the design system specifies.
    private static let loginInk = Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255)

    @Environment(\.isEnabled) private var isEnabled
    private let style: DSButton.Style

    public init(style: DSButton.Style) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSFont.headline)
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, isCapsule ? DSSpacing.space6 : 0)
            .frame(
                maxWidth: isCapsule ? .infinity : nil,
                minHeight: isCapsule ? Self.capsuleHeight : DSSpacing.tapMin
            )
            .background { background }
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(opacity(isPressed: configuration.isPressed))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var isCapsule: Bool {
        switch style {
        case .plain, .destructive: false
        default: true
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: DSPalette.textPrimary
        case .secondary: DSPalette.tintInk
        case .plain: DSPalette.bubblegum
        case .destructive: DSColor.destructive
        case .spotify, .appleMusic: Self.loginInk
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            DSPrimaryGradient()
                .clipShape(Capsule())
                .dsShadow(.glow)
        case .secondary:
            Capsule().fill(DSPalette.tintFill)
        case .spotify:
            Capsule().fill(DSPalette.spotifyGreen)
        case .appleMusic:
            Capsule().fill(DSPalette.textPrimary)
        case .plain, .destructive:
            Color.clear
        }
    }

    private func opacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return isPressed ? 0.85 : 1
    }
}

#Preview {
    VStack(spacing: DSSpacing.space3) {
        DSButton("Jugar") {}
        DSButton("Continuar", trailingSystemImage: "chevron.right") {}
        DSButton("Elegir otra lista", style: .secondary) {}
        HStack {
            DSButton("Cancelar", style: .plain) {}
            Spacer()
            DSButton("Cerrar sesión", style: .destructive) {}
        }
        DSButton("Continuar con Spotify", style: .spotify) {}
        DSButton("Continuar con Apple Music", style: .appleMusic) {}
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
