import SwiftUI

/// Semantic text styles of the design system.
public enum DSTextStyle: Sendable {
    /// Unbounded 800, 34/41, with the animated glow.
    case largeTitle
    /// Unbounded 800, 40/44, with the animated glow: app name and revealed year.
    case hero
    /// Unbounded 700, 22/28: card, sheet and revealed song titles.
    case title
    /// Unbounded 700, 20/26: block titles in sheets.
    case sectionTitle
    case headline
    case body
    case bodyStrong
    /// Metadata under a title, in `text-secondary`.
    case subheadline
    /// Section footers and notes, in `text-tertiary`.
    case footnote
    /// Small caps section headers, in `text-secondary`.
    case caption

    var font: Font {
        switch self {
        case .largeTitle: DSFont.largeTitle
        case .hero: DSTypeScale.hero
        case .title: DSFont.title
        case .sectionTitle: DSTypeScale.sectionTitle
        case .headline: DSFont.headline
        case .body: DSFont.body
        case .bodyStrong: DSFont.bodyStrong
        case .subheadline: DSTypeScale.subheadline
        case .footnote: DSFont.footnote
        case .caption: DSFont.caption
        }
    }

    /// Letter spacing from tokens.json (`letterSpacing` in em × font size).
    var tracking: CGFloat {
        switch self {
        case .largeTitle: -0.34
        case .hero: -0.8
        case .caption: 0.72
        default: 0
        }
    }

    /// Styles painted with the animated title glow when no color is given.
    var glows: Bool {
        self == .largeTitle || self == .hero
    }

    @MainActor var defaultColor: Color {
        switch self {
        case .subheadline, .caption: DSColor.textSecondary
        case .footnote: DSPalette.textTertiary
        default: DSColor.textPrimary
        }
    }
}

/// Text with a design-system style applied. Large Title and Hero glow unless a color is passed.
public struct DSText: View, DSLocalizableText {
    public var text: String
    private let style: DSTextStyle
    private let color: Color?

    public init(_ text: String = "", style: DSTextStyle = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some View {
        let label = Text(text)
            .font(style.font)
            .tracking(style.tracking)
        if let color {
            label.foregroundStyle(color)
        } else if style.glows {
            label.dsGlow()
        } else {
            label.foregroundStyle(style.defaultColor)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DSSpacing.space3) {
        DSText("Playlister", style: .hero)
        DSText("Elige una lista", style: .largeTitle)
        DSText("Bohemian Rhapsody", style: .title)
        DSText("Hitster España", style: .headline)
        DSText("312 canciones · Spotify", style: .subheadline)
        DSText("Mantén pulsada para ver canciones", style: .footnote)
    }
    .padding(DSSpacing.space4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DSColor.background)
}
