import PlaylisterUI
import SwiftUI

/// «Partida · sonando» and «Partida · revelada»: playlist and mode on top, the spinning vinyl, the round progress
/// and the controls. The first shuffled song plays on load and stops when the view goes away.
/// - Playing: Pause (Play while paused), Reveal and Next, which sends the song to the end of the queue.
/// - Revealed: the controls hide, the vinyl shows the cover and the song card rises at the bottom with Continue
///   under it, which takes the song out of the game and plays the next one.
/// - «Partida · bingo»: each round draws a category before its song plays; the background glow, the vinyl, the
///   progress bar and the tint take its color, and its name shows under the vinyl.
struct GameView: View {
    /// Room kept under the controls for the revealed song card, so the vinyl does not move when it appears.
    private static let revealCardHeight: CGFloat = 196

    @State private var viewModel: GameViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: GameDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            DSGameHeader(
                caption: String(localized: "game.playlist"),
                title: viewModel.viewData.playlist.name,
                badge: viewModel.modeSummary,
                badgeStyle: viewModel.viewData.settings.mode == .bingo ? .bingo : .standard
            )
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
        .background { DSAuraBackground(glow: category?.color) }
        .animation(.easeOut(duration: 0.4), value: category)
        .tint(category?.color ?? DSPalette.bubblegum)
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear {
            Task { await viewModel.stop() }
        }
    }

    private var player: some View {
        VStack(spacing: DSSpacing.space6) {
            DSVinyl(phase: vinylPhase, category: category, level: bingoLevel)
            DSProgressBar(
                progress: viewModel.progress,
                elapsed: viewModel.elapsedText,
                duration: viewModel.durationText,
                smoothing: GameViewModel.progressInterval,
                tint: category?.color
            )
            controls
            if let playbackError = viewModel.viewData.playbackError {
                DSText(playbackError, style: .footnote, color: DSColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Bingo category of the round, in the design system's terms. `nil` in the classic mode.
    private var category: DSBingoCategory? {
        viewModel.viewData.bingoCategory.map(DSBingoCategory.init)
    }

    private var bingoLevel: DSBingoLevel {
        viewModel.viewData.settings.bingoLevel == .expert ? .expert : .beginner
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
                    // A worded button, unlike the round Next, so it does not read as skipping the song.
                    DSButton(trailingSystemImage: "chevron.right") {
                        Task { await viewModel.continueToNextSong() }
                    }
                    .localized("game.continue")
                }
                .transition(DSSongRevealCard.revealTransition)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.revealCardHeight, alignment: .top)
    }

    /// The song's length, under the year.
    private var revealedDuration: DSSongRevealCard.Detail? {
        viewModel.revealedDurationText.map { .init(String(localized: "game.reveal.duration"), value: $0) }
    }

    @ViewBuilder private var controls: some View {
        if viewModel.viewData.isRevealed {
            // The round controls hide; Continue goes under the card.
            Color.clear
                .frame(height: DSGameControls.height)
                .accessibilityHidden(true)
        } else {
            DSGameControls(
                isPaused: viewModel.viewData.isPaused,
                texts: Self.controlTexts,
                togglePause: .init(isEnabled: viewModel.canTogglePause) {
                    Task { await viewModel.togglePause() }
                },
                reveal: .init(isEnabled: viewModel.canReveal) {
                    Task { await viewModel.reveal() }
                },
                next: .init(isEnabled: viewModel.canPlayNextSong) {
                    Task { await viewModel.playNextSong() }
                }
            )
            .transition(.opacity)
        }
    }

    private static var controlTexts: DSGameControls.Texts {
        DSGameControls.Texts(
            pause: String(localized: "game.pause"),
            play: String(localized: "game.play"),
            reveal: String(localized: "game.reveal"),
            next: String(localized: "game.next")
        )
    }
}

private extension DSBingoCategory {
    init(_ category: GameViewData.BingoCategory) {
        switch category {
        case .pink: self = .pink
        case .yellow: self = .yellow
        case .cyan: self = .cyan
        case .green: self = .green
        case .orange: self = .orange
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
