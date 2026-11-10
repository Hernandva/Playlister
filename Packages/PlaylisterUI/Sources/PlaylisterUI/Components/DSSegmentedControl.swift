import SwiftUI

/// Segmented control whose selected option wears the animated primary gradient, sliding between options.
/// Two or three short options: Canción entera / Fragmento, Clásico / Bingo, Principiante / Experto.
///
///     DSSegmentedControl(selection: $mode, segments: [
///         .init(.classic, title: String(localized: "settings.mode.classic")),
///         .init(.bingo, title: String(localized: "settings.mode.bingo"))
///     ])
public struct DSSegmentedControl<Value: Hashable>: View {
    public struct Segment: Identifiable {
        public let value: Value
        /// Already localised title.
        public let title: String
        public var id: Value { value }

        public init(_ value: Value, title: String) {
            self.value = value
            self.title = title
        }
    }

    private static var segmentHeight: CGFloat { 34 }
    private static var inset: CGFloat { 2 }
    /// 14 pt semibold, as the SegmentedControl guide specifies.
    private static var titleFont: Font { .system(size: 14, weight: .semibold) }

    @Binding private var selection: Value
    private let segments: [Segment]
    @Namespace private var namespace

    public init(selection: Binding<Value>, segments: [Segment]) {
        self._selection = selection
        self.segments = segments
    }

    public var body: some View {
        HStack(spacing: Self.inset) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .padding(Self.inset)
        .background(DSColor.fillSecondary, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func segmentButton(_ segment: Segment) -> some View {
        let isSelected = segment.value == selection
        let shape = RoundedRectangle(cornerRadius: DSRadius.control - Self.inset, style: .continuous)
        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selection = segment.value
            }
        } label: {
            Text(segment.title)
                .font(Self.titleFont)
                .lineLimit(1)
                .foregroundStyle(isSelected ? DSColor.textPrimary : DSColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: Self.segmentHeight)
                .background {
                    if isSelected {
                        DSPrimaryGradient()
                            .clipShape(shape)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var mode = "classic"
    DSSegmentedControl(selection: $mode, segments: [
        .init("classic", title: "Clásico"),
        .init("bingo", title: "Bingo")
    ])
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
