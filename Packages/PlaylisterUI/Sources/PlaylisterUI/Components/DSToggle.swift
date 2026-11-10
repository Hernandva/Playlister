import SwiftUI

/// Switch row: label on the left and a 51 × 31 pt switch filled with the animated primary gradient when on.
/// It always sits in a `DSListGroup`.
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
        .toggleStyle(DSSwitchToggleStyle())
        .padding(.horizontal, DSSpacing.space4)
        .frame(minHeight: DSListRow.minHeight)
    }
}

/// Toggle style of the design system. VoiceOver still sees a native switch.
public struct DSSwitchToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DSSpacing.space3) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            DSSwitchTrack(isOn: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                configuration.isOn.toggle()
            }
        }
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
        }
    }
}

private struct DSSwitchTrack: View {
    /// Track when off (#3A2A50), as the Toggle guide of the design system specifies.
    private static let offTrack = Color(red: 58 / 255, green: 42 / 255, blue: 80 / 255)
    private static let size = CGSize(width: 51, height: 31)
    private static let knob: CGFloat = 27
    private static let inset: CGFloat = 2

    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(Self.offTrack)
            if isOn {
                DSPrimaryGradient()
                    .clipShape(Capsule())
                    .transition(.opacity)
            }
            Circle()
                .fill(DSPalette.textPrimary)
                .frame(width: Self.knob, height: Self.knob)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .padding(Self.inset)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

#Preview {
    @Previewable @State var decade = true
    @Previewable @State var nearYears = false
    DSListGroup {
        DSToggle("Década", isOn: $decade)
        DSToggle("± 2 años", isOn: $nearYears)
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
