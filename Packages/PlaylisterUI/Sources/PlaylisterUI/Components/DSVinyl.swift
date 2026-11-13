import SwiftUI

/// Spinning vinyl at the centre of the game.
///
/// - `playing`: turns every 1.8 s. The centre wears the primary gradient and 7 white equalizer bars
///   that do not turn with the disc. Pass `levels` (0…1 per bar, e.g. from an `AVAudioEngine` power tap)
///   to bind the bars to the audio; without them the bars animate on their own.
/// - `paused`: the playing vinyl, still. The disc stops at its angle and turns on from it when it plays again,
///   and the equalizer bars settle low.
/// - `revealed`: turns every 6 s and the album cover pops in (scale 0.6 → 1). With `isPaused` (e.g. the song
///   ended) the disc stops at its angle, and turns on from it when it is `false` again.
/// - Bingo: with a `category`, grooves, ring and glow take its color, the centre is solid with `bg-night` bars,
///   and the category name appears under the disc.
/// - With Reduce Motion the disc does not turn and the bars are static.
public struct DSVinyl: View {
    public enum Phase: Equatable, Sendable {
        case playing
        case paused
        case revealed(cover: URL?, isPaused: Bool = false)
    }

    private let phase: Phase
    private let category: DSBingoCategory?
    private let level: DSBingoLevel
    private let levels: [Double]?
    private let diameter: CGFloat

    public init(
        phase: Phase,
        category: DSBingoCategory? = nil,
        level: DSBingoLevel = .beginner,
        levels: [Double]? = nil,
        diameter: CGFloat = 250
    ) {
        self.phase = phase
        self.category = category
        self.level = level
        self.levels = levels
        self.diameter = diameter
    }

    public var body: some View {
        VStack(spacing: DSSpacing.space4) {
            ZStack {
                DSVinylDisc(tint: category?.color, secondsPerTurn: isRevealed ? 6 : 1.8, isSpinning: isSpinning)
                center
            }
            .frame(width: diameter, height: diameter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isImage)
            if let category {
                Text(category.title(for: level))
                    .font(DSTypeScale.title2)
                    .foregroundStyle(category.color)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: phase)
    }

    @ViewBuilder private var center: some View {
        switch phase {
        case .playing, .paused:
            DSEqualizerCenter(tint: category?.color, levels: levels, isPaused: phase == .paused)
                .frame(width: diameter * 0.456, height: diameter * 0.456)
                .transition(.opacity)
        case .revealed(let cover, _):
            DSVinylLabel(cover: cover)
                .frame(width: diameter * 0.56, height: diameter * 0.56)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private var isRevealed: Bool {
        if case .revealed = phase { true } else { false }
    }

    /// `false` while the vinyl is paused, whether it is playing or revealed.
    private var isSpinning: Bool {
        switch phase {
        case .playing: true
        case .paused: false
        case .revealed(_, let isPaused): !isPaused
        }
    }

    private var accessibilityText: String {
        switch phase {
        case .playing:
            Bundle.main.localizedString(forKey: "vinyl.playing", value: "Vinilo sonando", table: nil)
        case .paused:
            Bundle.main.localizedString(forKey: "vinyl.paused", value: "Vinilo en pausa", table: nil)
        case .revealed:
            Bundle.main.localizedString(forKey: "vinyl.revealed", value: "Vinilo revelado con portada", table: nil)
        }
    }
}

/// Grooves, a turning conic sheen, the outer ring and the glow.
private struct DSVinylDisc: View {
    /// Groove colors (#121016 / #1D1724), as the Vinyl guide specifies.
    private static let groove = Color(red: 18 / 255, green: 16 / 255, blue: 22 / 255)
    private static let grooveLight = Color(red: 29 / 255, green: 23 / 255, blue: 36 / 255)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// When the disc stopped, while it is still.
    @State private var stoppedAt: Date?
    /// Seconds the disc has been still, taken out of the clock so it turns on from where it stopped.
    @State private var stillTime: TimeInterval = 0
    let tint: Color?
    let secondsPerTurn: TimeInterval
    let isSpinning: Bool

    var body: some View {
        ZStack {
            grooves
            TimelineView(.animation(paused: reduceMotion || !isSpinning)) { context in
                sheen.rotationEffect(.degrees(reduceMotion ? 0 : angle(at: stoppedAt ?? context.date)))
            }
        }
        .onAppear {
            if !isSpinning { stoppedAt = .now }
        }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                stillTime += stoppedAt.map { Date.now.timeIntervalSince($0) } ?? 0
                stoppedAt = nil
            } else {
                stoppedAt = .now
            }
        }
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(tint?.opacity(0.5) ?? DSPalette.orchid.opacity(0.22), lineWidth: 2).padding(-2))
        .shadow(
            color: tint?.opacity(0.55) ?? DSShadow.disc.color,
            radius: DSShadow.disc.radius,
            x: 0,
            y: DSShadow.disc.yOffset
        )
    }

    /// Repeating radial grooves: 2 pt dark, 2 pt light. They look the same at any angle, so they do not turn.
    private var grooves: some View {
        Canvas { graphics, size in
            let bounds = CGRect(origin: .zero, size: size)
            graphics.fill(Path(ellipseIn: bounds), with: .color(Self.groove))
            var radius: CGFloat = 3
            while radius < size.width / 2 {
                let ring = bounds.insetBy(dx: size.width / 2 - radius, dy: size.height / 2 - radius)
                graphics.stroke(Path(ellipseIn: ring), with: .color(Self.grooveLight), lineWidth: 2)
                radius += 4
            }
            if let tint {
                graphics.fill(Path(ellipseIn: bounds), with: .color(tint.opacity(0.18)))
            }
        }
    }

    private var sheen: some View {
        AngularGradient(
            stops: [
                .init(color: .white.opacity(0), location: 0),
                .init(color: .white.opacity(0.13), location: 40 / 360),
                .init(color: .white.opacity(0), location: 85 / 360),
                .init(color: .white.opacity(0), location: 180 / 360),
                .init(color: .white.opacity(0.1), location: 220 / 360),
                .init(color: .white.opacity(0), location: 265 / 360),
                .init(color: .white.opacity(0), location: 1)
            ],
            center: .center
        )
    }

    private func angle(at date: Date) -> Double {
        (date.timeIntervalSinceReferenceDate - stillTime)
            .truncatingRemainder(dividingBy: secondsPerTurn) / secondsPerTurn * 360
    }
}

/// Centre of the playing vinyl: primary gradient (or the category color) with 7 equalizer bars.
/// Paused, the bars settle at their lowest.
private struct DSEqualizerCenter: View {
    private static let restScale: CGFloat = 0.25

    /// Bar loops between 0.7 and 1.1 s, out of phase.
    private static let durations: [TimeInterval] = [0.7, 1.0, 0.8, 1.1, 0.75, 0.9, 0.85]
    private static let offsets: [TimeInterval] = [0, 0.4, 0.2, 0.6, 0.1, 0.3, 0.5]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tint: Color?
    let levels: [Double]?
    let isPaused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let tint {
                    Circle().fill(tint)
                } else {
                    DSPrimaryGradient().clipShape(Circle())
                }
                TimelineView(.animation(paused: reduceMotion || levels != nil || isPaused)) { context in
                    HStack(spacing: 4) {
                        ForEach(Self.durations.indices, id: \.self) { index in
                            Capsule()
                                .fill(tint == nil ? DSPalette.textPrimary : DSColor.background)
                                .frame(width: 5, height: proxy.size.height * 0.36)
                                .scaleEffect(x: 1, y: scale(of: index, at: context.date), anchor: .bottom)
                        }
                    }
                    .animation(.easeOut(duration: 0.3), value: isPaused)
                }
            }
        }
    }

    private func scale(of index: Int, at date: Date) -> CGFloat {
        if isPaused {
            return Self.restScale
        }
        if let levels, levels.indices.contains(index) {
            return 0.25 + 0.75 * min(max(levels[index], 0), 1)
        }
        if reduceMotion {
            return 0.6
        }
        let phase = DSMotion.phase(at: date.addingTimeInterval(Self.offsets[index]), duration: Self.durations[index])
        return 0.25 + 0.75 * phase
    }
}

/// Album cover of the revealed vinyl, with a white ring and the `bg-night` centre hole.
private struct DSVinylLabel: View {
    let cover: URL?

    var body: some View {
        GeometryReader { proxy in
            let hole = proxy.size.width * 0.086
            DSCoverImage(url: cover)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 4).padding(-4))
                .overlay(Circle().fill(DSColor.background).frame(width: hole, height: hole))
        }
    }
}

#Preview {
    @Previewable @State var revealed = false
    @Previewable @State var paused = false
    VStack(spacing: DSSpacing.space8) {
        DSVinyl(phase: revealed ? .revealed(cover: nil, isPaused: paused) : (paused ? .paused : .playing))
        DSVinyl(phase: paused ? .paused : .playing, category: .green, diameter: 180)
        HStack(spacing: DSSpacing.space3) {
            DSButton(paused ? "Reproducir" : "Pausa", style: .secondary) { paused.toggle() }
            DSButton(revealed ? "Siguiente" : "Revelar", style: .secondary) { revealed.toggle() }
        }
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
