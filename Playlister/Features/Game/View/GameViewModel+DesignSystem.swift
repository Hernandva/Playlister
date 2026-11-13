import PlaylisterUI
import SwiftUI

/// The game's state in the design system's terms, shared by the iPhone's `GameView` and the TV's
/// `GameExternalDisplayView` so both show the same round.
extension GameViewModel {
    /// Bingo category of the round. `nil` in the classic mode.
    var category: DSBingoCategory? {
        viewData.bingoCategory.map(DSBingoCategory.init)
    }

    var bingoLevel: DSBingoLevel {
        viewData.settings.bingoLevel == .expert ? .expert : .beginner
    }

    /// Style of the mode chip at the top: the round's category in the Bingo mode.
    var badgeStyle: DSChip.Style {
        viewData.settings.mode == .bingo ? .bingo(category) : .standard
    }

    var vinylPhase: DSVinyl.Phase {
        if viewData.isRevealed {
            // The song keeps sounding after Reveal; when it ends the game pauses, and so does the disc.
            return .revealed(cover: currentSong?.largeCover ?? currentSong?.cover, isPaused: viewData.isPaused)
        }
        return viewData.isPaused ? .paused : .playing
    }

    /// The album, under the revealed song's title.
    var revealedDetails: [DSSongRevealCard.Detail] {
        currentSong?.album.map { [.init(String(localized: "game.reveal.album"), value: $0)] } ?? []
    }

    /// Icon after the artist: solo artist or group, once MusicBrainz answers.
    var revealedArtistKind: DSSongRevealCard.ArtistKind? {
        switch viewData.artistKind {
        case .solo: .init(.solo, label: String(localized: "game.reveal.artist.solo"))
        case .group: .init(.group, label: String(localized: "game.reveal.artist.group"))
        case nil: nil
        }
    }

    /// The song's length, under the year.
    var revealedDuration: DSSongRevealCard.Detail? {
        revealedDurationText.map { .init(String(localized: "game.reveal.duration"), value: $0) }
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
