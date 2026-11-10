import SwiftUI

/// Root container of every screen: scrollable, with the screen background and margins of the design system.
public struct DSScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                content
            }
            .padding(.horizontal, DSSpacing.medium)
            .padding(.vertical, DSSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DSColor.background.ignoresSafeArea())
    }
}
