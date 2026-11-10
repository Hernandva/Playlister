import SwiftUI

/// Timing of the looping animations of the design system (gradients and title glow).
///
/// The loops follow the CSS keyframes of the design system: 0% → 100% → 0%, eased on each half.
/// With Reduce Motion on, every loop stays on its first frame.
enum DSMotion {
    /// Primary gradient loop: 8 s, ease.
    static let gradientDuration: TimeInterval = 8
    /// Title glow loop: 6 s, ease-in-out.
    static let glowDuration: TimeInterval = 6

    /// Progress of a looping animation at `date`, from 0 to 1 and back to 0 over `duration`.
    static func phase(at date: Date, duration: TimeInterval) -> Double {
        let progress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: duration) / duration
        let half = progress < 0.5 ? progress * 2 : (1 - progress) * 2
        return half * half * (3 - 2 * half)
    }
}
