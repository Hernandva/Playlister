import SwiftUI

/// Root container of every screen: scrollable, on the aura background, with `space-4` margins
/// and `space-6` between blocks. The app is always dark.
public struct DSScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.space6) {
                content
            }
            .padding(.horizontal, DSSpacing.space4)
            .padding(.vertical, DSSpacing.space6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background { DSAuraBackground() }
        .tint(DSPalette.bubblegum)
        .preferredColorScheme(.dark)
    }
}

/// Screen background: `bg-night` with a `violet` radial at the top and a `magenta` one at the opposite corner.
/// Use it behind sheets and full-screen views that are not a `DSScreen`.
public struct DSAuraBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            DSColor.background
            EllipticalGradient(
                colors: [DSPalette.violet.opacity(0.45), .clear],
                center: UnitPoint(x: 0.15, y: 0),
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            EllipticalGradient(
                colors: [DSPalette.magenta.opacity(0.26), .clear],
                center: UnitPoint(x: 1, y: 0.85),
                startRadiusFraction: 0,
                endRadiusFraction: 0.55
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    DSScreen {
        DSText("Elige una lista", style: .largeTitle)
        DSButton("Jugar") {}
    }
}
