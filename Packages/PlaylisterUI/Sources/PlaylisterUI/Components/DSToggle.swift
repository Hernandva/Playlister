import SwiftUI

/// Switch with a label.
public struct DSToggle: View, DSLocalizableText {
    public var text: String
    @Binding private var isOn: Bool

    public init(_ text: String = "", isOn: Binding<Bool>) {
        self.text = text
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(text)
                .font(DSFont.body)
                .foregroundStyle(DSColor.textPrimary)
        }
        .tint(DSColor.accent)
        .frame(minHeight: DSSpacing.tapMin)
    }
}

#Preview {
    DSToggle("Notifications", isOn: .constant(true))
        .padding()
}
