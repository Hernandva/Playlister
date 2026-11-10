import SwiftUI

/// Row with a title, an optional subtitle and an optional chevron. `.localized(_:)` localises the title.
public struct DSListRow: View, DSLocalizableText {
    public var text: String
    private let subtitle: String?
    private let showsChevron: Bool

    public init(_ text: String = "", subtitle: String? = nil, showsChevron: Bool = false) {
        self.text = text
        self.subtitle = subtitle
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: DSSpacing.small) {
            VStack(alignment: .leading, spacing: DSSpacing.xSmall) {
                Text(text)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DSFont.footnote)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DSColor.textSecondary)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.surface)
    }
}

#Preview {
    VStack(spacing: 0) {
        DSListRow("Account", subtitle: "Signed in", showsChevron: true)
        DSListRow("Privacy", showsChevron: true)
    }
}
