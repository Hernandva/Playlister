import SwiftUI

/// Single-line text input. `text` is the placeholder, so `.localized(_:)` localises it.
public struct DSTextField: View, DSLocalizableText {
    public var text: String
    @Binding private var value: String

    public init(_ placeholder: String = "", value: Binding<String>) {
        self.text = placeholder
        self._value = value
    }

    public var body: some View {
        TextField(text, text: $value)
            .textFieldStyle(.plain)
            .font(DSFont.body)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.medium)
            .frame(minHeight: DSSpacing.tapMin)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }
}

#Preview {
    DSTextField("Email", value: .constant(""))
        .padding()
}
