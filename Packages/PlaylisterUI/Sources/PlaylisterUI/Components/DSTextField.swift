import SwiftUI

/// Single-line text input on `fill`, like the native search field. `text` is the placeholder,
/// so `.localized(_:)` localises it. Pass `systemImage: "magnifyingglass"` for a search field.
public struct DSTextField: View, DSLocalizableText {
    public var text: String
    @Binding private var value: String
    private let systemImage: String?

    public init(_ placeholder: String = "", value: Binding<String>, systemImage: String? = nil) {
        self.text = placeholder
        self._value = value
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space2) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
            TextField(text: $value, prompt: Text(text).foregroundStyle(DSColor.textSecondary)) {
                Text(text)
            }
            .textFieldStyle(.plain)
            .font(DSFont.body)
            .foregroundStyle(DSColor.textPrimary)
            .tint(DSPalette.bubblegum)
        }
        .padding(.horizontal, DSSpacing.space3)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.fillSecondary, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }
}

#Preview {
    DSTextField("Buscar listas", value: .constant(""), systemImage: "magnifyingglass")
        .padding(DSSpacing.space4)
        .background(DSColor.background)
}
