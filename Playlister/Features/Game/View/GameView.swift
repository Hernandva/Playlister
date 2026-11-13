import PlaylisterUI
import SwiftUI

/// «Partida · sonando» and «Partida · revelada»: playlist and mode on top, the spinning vinyl, the round progress
/// and the controls. The first shuffled song plays on load and stops when the view goes away.
/// - Playing: Pause (Play while paused), Reveal and Next, which sends the song to the end of the queue.
/// - Revealed: the controls hide, the vinyl shows the cover and the song card rises at the bottom with Continue
///   under it, which takes the song out of the game and plays the next one.
struct GameView: View {
    /// Room kept under the controls for the revealed song card, so the vinyl does not move when it appears.
    private static let revealCardHeight: CGFloat = 196
    private static let controlsSpacing = DSSpacing.space8 + DSSpacing.space4
    /// Height of the round controls (`DSIconButton.glass`), kept while they are hidden so the vinyl does not move.
    private static let controlsHeight: CGFloat = 60

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
            case .finished:
                DSText(style: .headline).localized("game.finished")
                    .multilineTextAlignment(.center)
            case .failed(let message):
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
            Spacer(minLength: DSSpacing.space6)
            revealArea
        }
        .animation(.easeOut(duration: 0.4), value: viewModel.viewData.isRevealed)
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
            DSVinyl(phase: vinylPhase)
            DSProgressBar(
                progress: viewModel.progress,
                elapsed: viewModel.elapsedText,
                duration: viewModel.durationText,
                smoothing: GameViewModel.progressInterval
            )
            controls
            if let playbackError = viewModel.viewData.playbackError {
                DSText(playbackError, style: .footnote, color: DSColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var vinylPhase: DSVinyl.Phase {
        if viewModel.viewData.isRevealed {
            // The song keeps sounding after Reveal; when it ends the game pauses, and so does the disc.
            return .revealed(
                cover: viewModel.currentSong?.largeCover ?? viewModel.currentSong?.cover,
                isPaused: viewModel.viewData.isPaused
            )
        }
        return viewModel.viewData.isPaused ? .paused : .playing
    }

    /// The revealed song's card and Continue under it, in the room kept for them under the controls.
    private var revealArea: some View {
        ZStack(alignment: .top) {
            if viewModel.viewData.isRevealed, let song = viewModel.currentSong {
                VStack(spacing: DSSpacing.space4) {
                    DSSongRevealCard(
                        title: song.title,
                        artist: song.artist,
                        year: viewModel.revealedYear,
                        details: song.album.map { [.init(String(localized: "game.reveal.album"), value: $0)] } ?? [],
                        trailingDetail: revealedDuration
                    )
                    continueButton
                }
                .transition(DSSongRevealCard.revealTransition)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.revealCardHeight, alignment: .top)
    }

    /// A worded button, unlike the round Next, so it does not read as skipping the song.
    private var continueButton: some View {
        Button {
            Task { await viewModel.continueToNextSong() }
        } label: {
            HStack(spacing: DSSpacing.space2) {
                Text("game.continue")
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(DSButtonStyle(style: .primary))
    }

    /// The song's length, under the year.
    private var revealedDuration: DSSongRevealCard.Detail? {
        viewModel.revealedDurationText.map { .init(String(localized: "game.reveal.duration"), value: $0) }
    }

    @ViewBuilder private var controls: some View {
        if viewModel.viewData.isRevealed {
            // The round controls hide; Continue goes under the card.
            Color.clear
                .frame(height: Self.controlsHeight)
                .accessibilityHidden(true)
        } else {
            playingControls
                .transition(.opacity)
        }
    }

    private var playingControls: some View {
        HStack(spacing: Self.controlsSpacing) {
            DSIconButton(systemImage: viewModel.viewData.isPaused ? "play.fill" : "pause.fill") {
                Task { await viewModel.togglePause() }
            }
            .localized(viewModel.viewData.isPaused ? "game.play" : "game.pause")
            .disabled(!viewModel.canTogglePause)
            DSIconButton(systemImage: "questionmark.circle.fill") {
                Task { await viewModel.reveal() }
            }
            .localized("game.reveal")
            .disabled(!viewModel.canReveal)
            DSIconButton(systemImage: "forward.end.fill") {
                Task { await viewModel.playNextSong() }
            }
            .localized("game.next")
            .disabled(!viewModel.canPlayNextSong)
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
