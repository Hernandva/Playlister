import SwiftUI

/// Shadow tokens of the design system (`shadow.tokens` in tokens.json).
///
/// The token generator does not read shadows yet, so their values live here.
/// SwiftUI's radius is half the CSS blur.
public enum DSShadow: Sendable {
    /// `0 10px 30px rgba(194,24,111,0.35)`: primary button with the gradient.
    case glow
    /// `0 14px 34px rgba(123,47,247,0.35)`: cover mosaics.
    case card
    /// `0 30px 80px rgba(123,47,247,0.55)`: vinyl during the game.
    case disc

    var color: Color {
        switch self {
        case .glow: DSPalette.gradientEnd.opacity(0.35)
        case .card: DSPalette.violet.opacity(0.35)
        case .disc: DSPalette.violet.opacity(0.55)
        }
    }

    var radius: CGFloat {
        switch self {
        case .glow: 15
        case .card: 17
        case .disc: 40
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .glow: 10
        case .card: 14
        case .disc: 30
        }
    }
}

public extension View {
    /// Applies a shadow token of the design system.
    func dsShadow(_ shadow: DSShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.yOffset)
    }
}
