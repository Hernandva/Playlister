import SwiftUI

/// Playback progress of the game: a 4 pt track (`orchid` at 20 %) filled with the animated primary gradient,
/// with the elapsed and total times under it in `text-secondary` and tabular digits.
///
/// Times are passed already formatted («0:08», «0:20»).
///
/// When `progress` is read on a timer, pass the timer's interval as `smoothing`: the fill then grows linearly
/// over that time instead of jumping at each reading. Going back (a new song at 0) is never animated, and with
/// Reduce Motion the fill jumps.
public struct DSProgressBar: View {
    private static let trackHeight: CGFloat = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownProgress: Double = 0

    private let progress: Double
    private let elapsed: String
    private let duration: String
    private let width: CGFloat
    private let smoothing: TimeInterval

    /// - Parameters:
    ///   - progress: 0…1. Values outside the range are clamped.
    ///   - elapsed: Elapsed time, formatted.
    ///   - duration: Total time, formatted.
    ///   - width: Width of the bar. 230 pt under the 250 pt vinyl.
    ///   - smoothing: Seconds the fill takes to reach a new, higher `progress`. 0 jumps to it.
    public init(
        progress: Double,
        elapsed: String,
        duration: String,
        width: CGFloat = 230,
        smoothing: TimeInterval = 0
    ) {
        self.progress = min(max(progress, 0), 1)
        self.elapsed = elapsed
        self.duration = duration
        self.width = width
        self.smoothing = smoothing
    }

    public var body: some View {
        VStack(spacing: DSSpacing.space2) {
            Capsule()
                .fill(DSPalette.orchid.opacity(0.2))
                .overlay(alignment: .leading) {
                    DSPrimaryGradient()
                        .frame(width: width * shownProgress)
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
        .onAppear { shownProgress = progress }
        .onChange(of: progress) { oldValue, newValue in
            let animates = newValue > oldValue && smoothing > 0 && !reduceMotion
            withAnimation(animates ? .linear(duration: smoothing) : nil) {
                shownProgress = newValue
            }
        }
    }
}

#Preview("Smoothed") {
    @Previewable @State var seconds = 0
    DSProgressBar(
        progress: Double(seconds) / 20,
        elapsed: Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond)),
        duration: "0:20",
        smoothing: 1
    )
    .padding(DSSpacing.space6)
    .background(DSColor.background)
    .task {
        while seconds < 20 {
            try? await Task.sleep(for: .seconds(1))
            seconds += 1
        }
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
