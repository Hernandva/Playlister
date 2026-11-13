import SwiftUI

/// Root of a screen shown on an external display (a TV through AirPlay or a cable): lays its content out on a fixed
/// canvas, 960 × 540 pt (16:9) by default, and scales it to fill the display, so the components keep the sizes they
/// have on the iPhone and grow with the TV. The aura background fills the whole display, letterbox included.
/// The app is always dark.
public struct DSExternalDisplayCanvas<Content: View>: View {
    /// The canvas the content is laid out on: 16:9 at about the size of an iPhone in landscape.
    public static var defaultSize: CGSize { CGSize(width: 960, height: 540) }

    private let size: CGSize
    private let glow: Color?
    private let content: Content

    /// - Parameters:
    ///   - size: Size the content is laid out at, before it is scaled to the display.
    ///   - glow: Color of the aura's centre radial, e.g. the round's Bingo category.
    public init(size: CGSize = Self.defaultSize, glow: Color? = nil, @ViewBuilder content: () -> Content) {
        self.size = size
        self.glow = glow
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)
            content
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background { DSAuraBackground(glow: glow) }
        .ignoresSafeArea()
        .tint(glow ?? DSPalette.bubblegum)
        .preferredColorScheme(.dark)
    }
}

#Preview(traits: .landscapeLeft) {
    DSExternalDisplayCanvas(glow: DSBingoCategory.green.color) {
        VStack(spacing: DSSpacing.space6) {
            DSText("Playlister", style: .hero)
            DSVinyl(phase: .playing, category: .green)
        }
    }
}
