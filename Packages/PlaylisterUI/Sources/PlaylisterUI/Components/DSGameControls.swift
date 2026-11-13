import SwiftUI

/// Round controls of the game: Pause (Play while paused), Reveal and Next, as 60 pt `glass` `DSIconButton`s
/// with 48 pt between them. A control that is not available is shown disabled.
///
/// Hide it on the revealed view and keep `DSGameControls.height` of room instead, so the vinyl does not move.
/// Strings are passed already localised; they are the buttons' accessibility labels.
public struct DSGameControls: View {
    /// Height of the controls, for the room kept while they are hidden.
    public static let height: CGFloat = 60
    private static let spacing = DSSpacing.space8 + DSSpacing.space4

    /// Accessibility labels of the buttons.
    public struct Texts: Sendable {
        public let pause: String
        public let play: String
        public let reveal: String
        public let next: String

        public init(pause: String, play: String, reveal: String, next: String) {
            self.pause = pause
            self.play = play
            self.reveal = reveal
            self.next = next
        }
    }

    /// One control: whether it can be tapped now and what it does.
    public struct Control {
        public let isEnabled: Bool
        public let action: @MainActor () -> Void

        public init(isEnabled: Bool = true, action: @escaping @MainActor () -> Void) {
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    private let isPaused: Bool
    private let texts: Texts
    private let togglePause: Control
    private let reveal: Control
    private let next: Control

    /// - Parameters:
    ///   - isPaused: Shows Play instead of Pause.
    ///   - togglePause: Pause or Play, after `isPaused`.
    public init(isPaused: Bool, texts: Texts, togglePause: Control, reveal: Control, next: Control) {
        self.isPaused = isPaused
        self.texts = texts
        self.togglePause = togglePause
        self.reveal = reveal
        self.next = next
    }

    public var body: some View {
        HStack(spacing: Self.spacing) {
            button(isPaused ? texts.play : texts.pause, systemImage: isPaused ? "play.fill" : "pause.fill", togglePause)
            button(texts.reveal, systemImage: "questionmark.circle.fill", reveal)
            button(texts.next, systemImage: "forward.end.fill", next)
        }
        .frame(height: Self.height)
    }

    private func button(_ text: String, systemImage: String, _ control: Control) -> some View {
        DSIconButton(text, systemImage: systemImage, action: control.action)
            .disabled(!control.isEnabled)
    }
}

#Preview {
    @Previewable @State var paused = false
    let texts = DSGameControls.Texts(pause: "Pausa", play: "Reproducir", reveal: "Revelar", next: "Siguiente")
    VStack(spacing: DSSpacing.space6) {
        DSGameControls(
            isPaused: paused,
            texts: texts,
            togglePause: .init { paused.toggle() },
            reveal: .init {},
            next: .init {}
        )
        DSGameControls(
            isPaused: false,
            texts: texts,
            togglePause: .init(isEnabled: false) {},
            reveal: .init(isEnabled: false) {},
            next: .init {}
        )
    }
    .padding(DSSpacing.space6)
    .background(DSColor.background)
}
