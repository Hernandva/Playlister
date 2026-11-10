import SwiftUI

/// Semantic text styles of the design system.
public enum DSTextStyle: Sendable {
    case largeTitle
    case title
    case headline
    case body
    case bodyStrong
    case footnote
    case caption

    var font: Font {
        switch self {
        case .largeTitle: DSFont.largeTitle
        case .title: DSFont.title
        case .headline: DSFont.headline
        case .body: DSFont.body
        case .bodyStrong: DSFont.bodyStrong
        case .footnote: DSFont.footnote
        case .caption: DSFont.caption
        }
    }

    @MainActor var defaultColor: Color {
        switch self {
        case .footnote, .caption: DSColor.textSecondary
        default: DSColor.textPrimary
        }
    }
}

/// Text with a design-system style applied.
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
        Text(text)
            .font(style.font)
            .foregroundStyle(color ?? style.defaultColor)
    }
}

#Preview {
    VStack(alignment: .leading) {
        DSText("Large title", style: .largeTitle)
        DSText("Body text")
        DSText("Footnote", style: .footnote)
    }
    .padding()
}
