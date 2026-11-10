import SwiftUI

/// Container that groups content on a surface.
public struct DSCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            content
        }
        .padding(DSSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
    }
}
