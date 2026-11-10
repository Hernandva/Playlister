import SwiftUI

/// Inset grouped list: `surface-2`, `radius-list` corners and a `hairline` between rows.
///
///     DSListGroup {
///         DSListRow("Clásico", accessory: .checkmark)
///         DSListRow("Bingo")
///     }
public struct DSListGroup<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { subviews in
            VStack(spacing: 0) {
                ForEach(Array(subviews.enumerated()), id: \.element.id) { index, subview in
                    subview
                    if index < subviews.count - 1 {
                        Rectangle()
                            .fill(DSColor.separator)
                            .frame(height: 1)
                            .padding(.leading, DSSpacing.space4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(DSPalette.surface2)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusList, style: .continuous))
    }
}
