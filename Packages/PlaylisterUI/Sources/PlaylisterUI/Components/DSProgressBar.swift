import SwiftUI

/// Playback progress of the game: a 4 pt track (`orchid` at 20 %) filled with the animated primary gradient,
/// with the elapsed and total times under it in `text-secondary` and tabular digits.
///
/// Times are passed already formatted («0:08», «0:20»).
public struct DSProgressBar: View {
    private static let trackHeight: CGFloat = 4

    private let progress: Double
    private let elapsed: String
    private let duration: String
    private let width: CGFloat

    /// - Parameters:
    ///   - progress: 0…1. Values outside the range are clamped.
    ///   - elapsed: Elapsed time, formatted.
    ///   - duration: Total time, formatted.
    ///   - width: Width of the bar. 230 pt under the 250 pt vinyl.
    public init(progress: Double, elapsed: String, duration: String, width: CGFloat = 230) {
        self.progress = min(max(progress, 0), 1)
        self.elapsed = elapsed
        self.duration = duration
        self.width = width
    }

    public var body: some View {
        VStack(spacing: DSSpacing.space2) {
            Capsule()
                .fill(DSPalette.orchid.opacity(0.2))
                .overlay(alignment: .leading) {
                    DSPrimaryGradient()
                        .frame(width: width * progress)
                        .clipShape(Capsule())
                }
                .frame(height: Self.trackHeight)
                .clipShape(Capsule())
            HStack {
                Text(elapsed)
                Spacer()
                Text(duration)
            }
            .font(DSFont.caption.weight(.regular))
            .monospacedDigit()
            .foregroundStyle(DSColor.textSecondary)
        }
        .frame(width: width)
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(elapsed) / \(duration)")
    }
}

#Preview {
    VStack(spacing: DSSpacing.space6) {
        DSProgressBar(progress: 0, elapsed: "0:00", duration: "0:20")
        DSProgressBar(progress: 0.4, elapsed: "0:08", duration: "0:20")
        DSProgressBar(progress: 1, elapsed: "0:20", duration: "0:20")
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
