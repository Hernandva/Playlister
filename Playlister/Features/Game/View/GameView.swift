import PlaylisterUI
import SwiftUI

/// «Partida · sonando»: playlist and mode on top, the spinning vinyl, the round progress and the
/// Pause, Reveal and Next controls. The first shuffled song plays on load and stops when the view goes away;
/// the controls and the progress are not connected yet.
struct GameView: View {
    /// Room kept under the controls for the revealed song card, so the vinyl does not move when it appears.
    private static let revealCardHeight: CGFloat = 196
    private static let controlsSpacing = DSSpacing.space8 + DSSpacing.space4

    @State private var viewModel: GameViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: GameDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: DSSpacing.space6)
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded:
                player
            case .failed(let message):
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
            Spacer(minLength: DSSpacing.space6)
            Color.clear
                .frame(height: Self.revealCardHeight)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, DSSpacing.space4)
        .padding(.bottom, DSSpacing.space6)
        .background { DSAuraBackground() }
        .tint(DSPalette.bubblegum)
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear {
            Task { await viewModel.stop() }
        }
    }

    private var header: some View {
        HStack(spacing: DSSpacing.space3) {
            VStack(alignment: .leading, spacing: DSSpacing.space1 / 2) {
                DSText(style: .caption).localized("game.playlist")
                DSText(viewModel.viewData.playlist.name, style: .headline)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            DSChip(viewModel.modeSummary)
        }
        .frame(minHeight: DSSpacing.tapMin)
    }

    private var player: some View {
        VStack(spacing: DSSpacing.space6) {
            DSVinyl(phase: .playing)
            DSProgressBar(
                progress: viewModel.progress,
                elapsed: viewModel.elapsedText,
                duration: viewModel.durationText
            )
            controls
            if let playbackError = viewModel.viewData.playbackError {
                DSText(playbackError, style: .footnote, color: DSColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: Self.controlsSpacing) {
            DSIconButton(systemImage: "pause.fill") {}
                .localized("game.pause")
            DSIconButton(systemImage: "questionmark.circle.fill") {}
                .localized("game.reveal")
            DSIconButton(systemImage: "forward.end.fill") {}
                .localized("game.next")
        }
    }
}

#Preview {
    NavigationStack {
        GameCoordinator(
            provider: .appleMusic,
            playlist: GameViewData.Playlist(id: "preview", name: "Road Trip", songCount: 42, covers: []),
            settings: GameViewData.Settings(
                playback: .clip,
                clipSeconds: 15,
                clipStart: .random,
                mode: .classic,
                bingoLevel: .beginner,
                bingoCategories: [.pink, .yellow, .cyan, .green, .orange]
            )
        ).start()
    }
}
