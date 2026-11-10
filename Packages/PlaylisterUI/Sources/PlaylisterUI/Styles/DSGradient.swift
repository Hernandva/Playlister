import SwiftUI

/// Animated primary gradient: `gradient-start` → `gradient-mid` → `gradient-end` at 120°,
/// three times wider than the view and sliding across it in an 8 s loop.
///
/// Only the main action of a screen, the selected control and the vinyl centre wear it.
/// Clip it to the shape that needs it: `DSPrimaryGradient().clipShape(Capsule())`.
public struct DSPrimaryGradient: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let phase = reduceMotion ? 0 : DSMotion.phase(at: context.date, duration: DSMotion.gradientDuration)
            // background-size 300%: the gradient line is 3 views long and moves 2 views.
            let start = -2 * phase
            LinearGradient(
                colors: [
                    DSPalette.gradientStart, DSPalette.gradientMid, DSPalette.gradientEnd, DSPalette.gradientStart
                ],
                startPoint: UnitPoint(x: start, y: 0),
                endPoint: UnitPoint(x: start + 3, y: 1)
            )
        }
        .accessibilityHidden(true)
    }
}

/// Moving glow of large titles: `orchid` → `bubblegum` → `orchid`, twice as wide as the text, 6 s loop.
struct DSGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let phase = reduceMotion ? 0 : DSMotion.phase(at: context.date, duration: DSMotion.glowDuration)
            content.foregroundStyle(
                LinearGradient(
                    colors: [DSPalette.orchid, DSPalette.bubblegum, DSPalette.orchid],
                    startPoint: UnitPoint(x: -phase, y: 0.5),
                    endPoint: UnitPoint(x: 2 - phase, y: 0.5)
                )
            )
        }
    }
}

public extension View {
    /// Paints the content with the animated title glow (Large Title, app name, revealed year).
    func dsGlow() -> some View {
        modifier(DSGlowModifier())
    }
}

#Preview {
    VStack(spacing: DSSpacing.space6) {
        DSPrimaryGradient()
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusCard, style: .continuous))
        Text("Playlister")
            .font(DSTypeScale.hero)
            .dsGlow()
    }
    .padding()
    .background(DSColor.background)
}
