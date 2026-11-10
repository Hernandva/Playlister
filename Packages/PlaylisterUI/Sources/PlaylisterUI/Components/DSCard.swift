import SwiftUI

/// Large block on `surface-1` with a `hairline` border, `radius-panel` corners and `space-5` padding.
public struct DSCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.radiusPanel, style: .continuous)
        VStack(alignment: .leading, spacing: DSSpacing.space3) {
            content
        }
        .padding(DSSpacing.space5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface, in: shape)
        .overlay(shape.strokeBorder(DSColor.separator, lineWidth: 1))
    }
}

#Preview {
    DSCard {
        DSText("Bohemian Rhapsody", style: .title)
        DSText("Queen · 1975", style: .subheadline)
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
