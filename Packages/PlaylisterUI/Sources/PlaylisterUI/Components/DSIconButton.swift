import SwiftUI

/// Round icon-only button.
///
/// - `play`: 96–132 pt, animated primary gradient with a `magenta` pulse (2.4 s). Only one, in Home.
/// - `glass`: 60 pt in the game, 44 pt in navigation bars. White at 8 % with an `orchid` border at 25 %.
/// - `gradient`: glass size with the primary gradient, for «Siguiente» on the revealed view.
///
/// `text` is the accessibility label («Jugar», «Pausa», «Siguiente», «Ajustes»), so `.localized(_:)` localises it.
/// Symbols: `play.fill`, `pause.fill`, `forward.end.fill`, `arrow.counterclockwise`, `slider.horizontal.3`.
public struct DSIconButton: View, DSLocalizableText {
    public enum Style: Sendable {
        case play
        case glass
        case gradient
    }

    public var text: String
    private let systemImage: String
    private let style: Style
    private let diameter: CGFloat
    private let action: @MainActor () -> Void

    /// - Parameter diameter: Defaults to 96 pt for `play` and 60 pt for the others. Use 44 pt in navigation bars.
    public init(
        _ text: String = "",
        systemImage: String,
        style: Style = .glass,
        diameter: CGFloat? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.text = text
        self.systemImage = systemImage
        self.style = style
        self.diameter = diameter ?? (style == .play ? 96 : 60)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .buttonStyle(DSIconButtonStyle(style, diameter: diameter))
        .accessibilityLabel(text)
    }
}

/// Look of `DSIconButton` for a label that is not a plain button, e.g. a `NavigationLink`:
///
///     NavigationLink(value: Route.settings) {
///         Image(systemName: "slider.horizontal.3")
///     }
///     .buttonStyle(DSIconButtonStyle(diameter: DSSpacing.tapMin))
///     .accessibilityLabel(String(localized: "providerStarter.settings"))
public struct DSIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let style: DSIconButton.Style
    private let diameter: CGFloat

    /// - Parameter diameter: Defaults to 96 pt for `play` and 60 pt for the others. Use 44 pt in navigation bars.
    public init(_ style: DSIconButton.Style = .glass, diameter: CGFloat? = nil) {
        self.style = style
        self.diameter = diameter ?? (style == .play ? 96 : 60)
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: diameter * 0.38, weight: .semibold))
            .foregroundStyle(DSPalette.textPrimary)
            .frame(width: diameter, height: diameter)
            .background { background }
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .play:
            DSPrimaryGradient()
                .clipShape(Circle())
                .background { DSPulseRing(diameter: diameter) }
        case .gradient:
            DSPrimaryGradient()
                .clipShape(Circle())
        case .glass:
            Circle()
                .fill(Color.white.opacity(0.08))
                .overlay(Circle().strokeBorder(DSPalette.orchid.opacity(0.25), lineWidth: 1))
        }
    }
}

/// Pressed feedback shared by the round buttons.
struct DSPressStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// `magenta` ring that grows 18 pt and fades out, 2.4 s loop. Static with Reduce Motion.
private struct DSPulseRing: View {
    private static let spread: CGFloat = 18
    private static let duration: TimeInterval = 2.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let diameter: CGFloat

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let phase = reduceMotion ? 1 : DSMotion.phase(at: context.date, duration: Self.duration)
            Circle()
                .fill(DSPalette.magenta.opacity(0.45 * (1 - phase)))
                .frame(width: diameter + 2 * Self.spread * phase, height: diameter + 2 * Self.spread * phase)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: DSSpacing.space6) {
        DSIconButton("Jugar", systemImage: "play.fill", style: .play) {}
        DSIconButton("Pausa", systemImage: "pause.fill") {}
        DSIconButton("Siguiente", systemImage: "forward.end.fill", style: .gradient) {}
        DSIconButton("Ajustes", systemImage: "slider.horizontal.3", diameter: 44) {}
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
