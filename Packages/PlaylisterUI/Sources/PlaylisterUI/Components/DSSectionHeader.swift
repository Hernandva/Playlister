import SwiftUI

/// Uppercased header placed above a group of rows.
public struct DSSectionHeader: View, DSLocalizableText {
    public var text: String

    public init(_ text: String = "") {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(DSFont.caption)
            .foregroundStyle(DSColor.textSecondary)
            .padding(.horizontal, DSSpacing.medium)
    }
}
