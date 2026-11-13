import PlaylisterUI
import SwiftUI

/// «Partida · TV»: the game on an external display (a TV through AirPlay or a cable), laid out in 16:9 for everybody
/// in the room. The playlist and mode on top; the spinning vinyl with the progress on the left; on the right, the
/// question while the song plays (the round's category, in its color, in the Bingo mode) and the revealed song's card
/// after Reveal. In the Bingo mode the round's category lights the background, as on the iPhone.
///
/// It has no controls: the display is not interactive, and the game is played on the iPhone. It does not own its view
/// model: it mirrors the one of the iPhone's `GameView`, which `GameExternalDisplaySession` hands to the display's
/// scene, so both screens show the same round.
struct GameExternalDisplayView: View {
    /// Width of the right column, where the question and the revealed card go.
    private static let revealColumnWidth: CGFloat = 420

    let viewModel: GameViewModel

    var body: some View {
        DSExternalDisplayCanvas(glow: viewModel.category?.color) {
            VStack(spacing: DSSpacing.space8) {
                DSGameHeader(
                    caption: String(localized: "game.playlist"),
                    title: viewModel.viewData.playlist.name,
                    badge: viewModel.modeSummary,
                    badgeStyle: viewModel.badgeStyle
                )
                Spacer(minLength: 0)
                content
                Spacer(minLength: 0)
            }
            .padding(DSSpacing.space8)
        }
        .animation(.easeOut(duration: 0.4), value: viewModel.viewData.isRevealed)
        .animation(.easeOut(duration: 0.4), value: viewModel.category)
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            HStack(spacing: DSSpacing.space8) {
                player
                revealColumn
                    .frame(width: Self.revealColumnWidth)
            }
        case .finished:
            DSText(style: .largeTitle).localized("game.finished")
                .multilineTextAlignment(.center)
        case .failed(let message):
            DSText(message, style: .headline, color: DSColor.destructive)
                .multilineTextAlignment(.center)
        }
    }

    private var player: some View {
        VStack(spacing: DSSpacing.space6) {
            DSVinyl(phase: viewModel.vinylPhase, category: viewModel.category, level: viewModel.bingoLevel)
            DSProgressBar(
                progress: viewModel.progress,
                elapsed: viewModel.elapsedText,
                duration: viewModel.durationText,
                smoothing: GameViewModel.progressInterval,
                tint: viewModel.category?.color
            )
        }
    }

    /// The question while the song plays, the revealed card after Reveal.
    private var revealColumn: some View {
        ZStack(alignment: .leading) {
            if viewModel.viewData.isRevealed, let song = viewModel.currentSong {
                DSSongRevealCard(
                    title: song.title,
                    artist: song.artist,
                    year: viewModel.revealedYear,
                    details: viewModel.revealedDetails,
                    trailingDetail: viewModel.revealedDuration,
                    artistKind: viewModel.revealedArtistKind
                )
                .transition(DSSongRevealCard.revealTransition)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.space3) {
                    if let category = viewModel.category {
                        // Bingo: the round's category is what the room has to answer.
                        DSText(category.title(for: viewModel.bingoLevel), style: .largeTitle, color: category.color)
                    } else {
                        DSText(style: .largeTitle).localized("game.externalDisplay.question")
                    }
                    if let playbackError = viewModel.viewData.playbackError {
                        DSText(playbackError, style: .body, color: DSColor.destructive)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
