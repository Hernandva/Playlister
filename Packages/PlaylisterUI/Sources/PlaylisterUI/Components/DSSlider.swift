import SwiftUI

/// Slider row of a grouped list: title and current value on top, the slider between its minimum and maximum
/// labels below. The track fills with `magenta`. Texts are passed localised.
///
///     DSSlider(
///         value: $seconds,
///         in: 5...60,
///         step: 5,
///         labels: .init(title: "Duración", value: "20 s", minimum: "5 s", maximum: "60 s")
///     )
public struct DSSlider: View {
    /// Already localised texts of the row.
    public struct Labels: Sendable {
        public let title: String
        /// Current value, e.g. «20 s». Also what VoiceOver reads.
        public let value: String
        public let minimum: String
        public let maximum: String

        public init(title: String, value: String, minimum: String, maximum: String) {
            self.title = title
            self.value = value
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    private let step: Double
    private let labels: Labels

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double, labels: Labels) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.labels = labels
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space2) {
            HStack {
                Text(labels.title)
                    .foregroundStyle(DSColor.textPrimary)
                Spacer(minLength: DSSpacing.space3)
                Text(labels.value)
                    .foregroundStyle(DSColor.textSecondary)
            }
            .font(DSFont.body)
            .accessibilityHidden(true)
            Slider(value: $value, in: bounds, step: step) {
                Text(labels.title)
            } minimumValueLabel: {
                boundLabel(labels.minimum)
            } maximumValueLabel: {
                boundLabel(labels.maximum)
            }
            .tint(DSPalette.magenta)
            .accessibilityValue(labels.value)
        }
        .padding(.horizontal, DSSpacing.space4)
        .padding(.vertical, DSSpacing.space3)
    }

    private func boundLabel(_ text: String) -> some View {
        Text(text)
            .font(DSFont.footnote)
            .foregroundStyle(DSPalette.textTertiary)
    }
}

#Preview {
    @Previewable @State var seconds = 20.0
    DSListGroup {
        DSSlider(
            value: $seconds,
            in: 5...60,
            step: 5,
            labels: .init(title: "Duración", value: "\(Int(seconds)) s", minimum: "5 s", maximum: "60 s")
        )
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
