import Foundation
import Observation
import PlaylisterData

@MainActor
@Observable
final class GameViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        /// Every song was revealed: the playlist is over.
        case finished
        case failed(String)
    }

    /// Songs in a row that cannot be played before the game gives up and shows the error.
    private static let maxSkippedSongs = 5
    /// How often the progress reads the player's time, in seconds: MusicKit does not announce it.
    /// The progress bar animates over the same time, so it grows without jumps.
    static let progressInterval: TimeInterval = 1
    /// Seconds before the end of a whole song within which a song that stops counts as ended: the player's last
    /// reading may fall a little short of its length.
    private static let endTolerance: TimeInterval = 2

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: GameViewData

    private let provider: MusicProvider
    private let fetchSongsUseCase: any FetchGameSongsUseCaseProtocol
    private let playerUseCase: any GamePlayerUseCaseProtocol
    private let playBackStatusUseCase: any GamePlayBackStatusUseCaseProtocol
    private let artistKindUseCase: any FetchArtistKindUseCaseProtocol
    /// `true` while a pause, a resume or a change of song is on its way, so a second tap does not overlap it and the
    /// status readings do not undo it.
    @ObservationIgnored private var isChangingPlayback = false
    /// Reads the player's time while a song plays.
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    /// Asks MusicBrainz for the kind of artist of the current song.
    @ObservationIgnored private var artistKindTask: Task<Void, Never>?

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameDependencies) {
        self.viewData = GameViewData(
            playlist: dependencies.resolvePlaylist(),
            settings: dependencies.resolveSettings()
        )
        self.provider = dependencies.resolveProvider()
        self.fetchSongsUseCase = dependencies.resolveFetchGameSongsUseCase()
        self.playerUseCase = dependencies.resolveGamePlayerUseCase()
        self.playBackStatusUseCase = dependencies.resolveGamePlayBackStatusUseCase()
        self.artistKindUseCase = dependencies.resolveFetchArtistKindUseCase()
    }

    /// Played share of the round, 0…1: of the clip, or of the whole song.
    var progress: Double {
        guard let length = roundLength, length > 0 else { return 0 }
        return elapsed / length
    }

    /// Time played since the round started.
    var elapsedText: String {
        Self.formatted(seconds: Int(elapsed))
    }

    /// The song that is playing: the first of the queue.
    var currentSong: GameViewData.Song? {
        viewData.queue?.first
    }

    /// Length of the round: the clip length, or the length of the song when it plays whole.
    var durationText: String {
        Self.formatted(seconds: Int(roundLength ?? 0))
    }

    /// Length of the round in seconds: the clip, or the whole song; `nil` while the song's length is unknown.
    private var roundLength: TimeInterval? {
        switch viewData.settings.playback {
        case .clip: TimeInterval(viewData.settings.clipSeconds)
        case .fullSong: viewData.round?.songDuration ?? currentSong?.duration
        }
    }

    /// Seconds played since the round started, from the player's time. 0 until the song sounds, and never past the
    /// round's length.
    private var elapsed: TimeInterval {
        guard let round = viewData.round else { return 0 }
        let played = max(0, viewData.playbackTime - round.startTime)
        guard let length = roundLength else { return played }
        return min(played, length)
    }

    private static func formatted(seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }

    /// Reads every song of the playlist, shuffles them into the queue and plays the first one.
    func load() async {
        state = .loading
        do {
            let songs = try await fetchSongsUseCase.execute(playlistID: viewData.playlist.id, provider: provider)
            guard !songs.isEmpty else {
                state = .failed(String(localized: "game.empty"))
                return
            }
            viewData.queue = songs.shuffled()
            state = .loaded
        } catch is CancellationError {
            state = .idle
            return
        } catch {
            state = .failed(error.localizedDescription)
            return
        }
        await playCurrentSong()
    }

    /// `false` until a song plays: there is nothing to pause yet.
    var canTogglePause: Bool {
        viewData.round != nil
    }

    /// Pauses the song, or plays it again from where it was paused.
    func togglePause() async {
        guard canTogglePause, !isChangingPlayback else { return }
        isChangingPlayback = true
        defer { isChangingPlayback = false }
        if viewData.isPaused {
            await resume()
        } else {
            await pause()
        }
    }

    /// `false` until a song plays and once it is revealed.
    var canReveal: Bool {
        viewData.round != nil && !viewData.isRevealed
    }

    /// Shows the current song's card. The song keeps sounding until it ends; a paused song plays again.
    func reveal() async {
        guard canReveal, !isChangingPlayback else { return }
        isChangingPlayback = true
        defer { isChangingPlayback = false }
        viewData.isRevealed = true
        if viewData.isPaused {
            await resume()
        }
    }

    /// After Reveal: stops the song, takes it out of the game for good and starts a new round with the next one.
    /// With no songs left the game is over.
    func continueToNextSong() async {
        guard viewData.isRevealed, !isChangingPlayback else { return }
        isChangingPlayback = true
        defer { isChangingPlayback = false }
        stopProgress()
        await playerUseCase.stop(provider: provider)
        viewData.queue?.removeFirst()
        guard currentSong != nil else {
            state = .finished
            return
        }
        await playCurrentSong()
    }

    /// `false` until the songs load.
    var canPlayNextSong: Bool {
        state == .loaded && viewData.queue?.isEmpty == false
    }

    /// Stops the song, sends it to the end of the queue and starts a new round with the next one.
    func playNextSong() async {
        guard canPlayNextSong, !isChangingPlayback else { return }
        isChangingPlayback = true
        defer { isChangingPlayback = false }
        stopProgress()
        await playerUseCase.stop(provider: provider)
        moveCurrentSongToEnd()
        await playCurrentSong()
    }

    private func pause() async {
        viewData.isPaused = true
        await playerUseCase.pause(provider: provider)
    }

    private func resume() async {
        do {
            try await playerUseCase.resume(provider: provider)
            viewData.isPaused = false
            viewData.playbackError = nil
            if progressTask == nil {
                startProgress()
            }
        } catch is CancellationError {
            return
        } catch {
            viewData.playbackError = Self.message(for: error as? GamePlaybackError ?? .unavailable)
        }
    }

    /// Stops the music when the user leaves the game.
    func stop() async {
        stopProgress()
        await playerUseCase.stop(provider: provider)
    }

    /// Plays the current song. When it cannot be played (missing or unavailable) it goes to the end of the queue and
    /// the next one plays, up to
    /// `maxSkippedSongs` in a row; errors of the account or the service stop and are shown, since every song would
    /// fail the same way.
    private func playCurrentSong() async {
        stopProgress()
        viewData.playbackError = nil
        drawBingoCategory()
        var skipped = 0
        while let song = currentSong {
            do {
                viewData.round = try await playerUseCase.play(
                    song: song,
                    settings: viewData.settings,
                    provider: provider
                )
                startProgress()
                loadArtistKind(of: song)
                return
            } catch is CancellationError {
                return
            } catch GamePlaybackError.unavailable where skipped < Self.maxSkippedSongs {
                skipped += 1
                moveCurrentSongToEnd()
            } catch {
                viewData.playbackError = Self.message(for: error as? GamePlaybackError ?? .unavailable)
                return
            }
        }
        viewData.playbackError = Self.message(for: .unavailable)
    }

    /// Asks for the kind of artist of the song that just started, while it plays, for the revealed card. A failure
    /// leaves it unknown: the card then shows no icon.
    private func loadArtistKind(of song: GameViewData.Song) {
        artistKindTask = Task { [weak self] in
            guard let self else { return }
            let kind = try? await artistKindUseCase.execute(song: song)
            guard !Task.isCancelled, currentSong?.id == song.id else { return }
            viewData.artistKind = kind
        }
    }

    /// In the Bingo mode, picks the category of the new round at random among the ones turned on in Settings.
    private func drawBingoCategory() {
        let settings = viewData.settings
        guard settings.mode == .bingo else {
            viewData.bingoCategory = nil
            return
        }
        viewData.bingoCategory = settings.bingoCategories.randomElement()
    }

    /// Sends the current song to the end of the queue, so the next one becomes the current song.
    private func moveCurrentSongToEnd() {
        guard var queue = viewData.queue, !queue.isEmpty else { return }
        queue.append(queue.removeFirst())
        viewData.queue = queue
    }

    /// Reads the player's time and status every `progressInterval` while the song is in the game, paused or not,
    /// until `stopProgress()` (a new song or leaving the game). The game follows the player: it pauses when the song
    /// stops sounding on its own (a call, Control Center, the end of the song) and plays again when the song sounds
    /// again from outside the app.
    private func startProgress() {
        progressTask = Task { [weak self] in
            // Until the song is heard once, a reading that is not playing is the player still starting.
            var hasPlayed = false
            while !Task.isCancelled {
                guard let self else { return }
                let reading = await playBackStatusUseCase.execute(provider: provider)
                guard !Task.isCancelled else { return }
                viewData.playbackTime = reading.time
                if !isChangingPlayback {
                    if roundHasEnded(isPlaying: reading.isPlaying, hasPlayed: hasPlayed) {
                        // The bar is full: the same as tapping Reveal, but a whole song that ended stays stopped.
                        viewData.isRevealed = true
                    }
                    followPlayer(isPlaying: reading.isPlaying, hasPlayed: hasPlayed)
                }
                hasPlayed = hasPlayed || reading.isPlaying
                try? await Task.sleep(for: .seconds(Self.progressInterval))
            }
        }
    }

    /// `true` when the progress bar is full and the song is not revealed yet: the clip's seconds have played, or the
    /// whole song stopped at its end. A song the user paused never counts.
    private func roundHasEnded(isPlaying: Bool, hasPlayed: Bool) -> Bool {
        guard !viewData.isRevealed, !viewData.isPaused, let round = viewData.round,
              let length = roundLength, length > 0 else { return false }
        let played = viewData.playbackTime - round.startTime
        if played >= length {
            return true
        }
        return hasPlayed && !isPlaying && length - played <= Self.endTolerance
    }

    /// Matches the game's pause to the player's status.
    private func followPlayer(isPlaying: Bool, hasPlayed: Bool) {
        if isPlaying, viewData.isPaused {
            viewData.isPaused = false
            viewData.playbackError = nil
        } else if !isPlaying, hasPlayed, !viewData.isPaused {
            viewData.isPaused = true
        }
    }

    /// Stops reading the player and empties the round, so the next one starts at 0, playing and hidden.
    private func stopProgress() {
        progressTask?.cancel()
        progressTask = nil
        artistKindTask?.cancel()
        artistKindTask = nil
        viewData.artistKind = nil
        viewData.round = nil
        viewData.playbackTime = 0
        viewData.isPaused = false
        viewData.isRevealed = false
    }
}

// MARK: - Texts of the screen

extension GameViewModel {
    /// Summary of the settings for the chip at the top: «Clásico · 20 s», «Clásico · Canción entera»
    /// or «Bingo · Principiante».
    var modeSummary: String {
        let settings = viewData.settings
        switch settings.mode {
        case .classic:
            let playback = switch settings.playback {
            case .clip: String(localized: "game.mode.clip \(settings.clipSeconds)")
            case .fullSong: String(localized: "game.mode.fullSong")
            }
            return "\(String(localized: "settings.mode.classic")) · \(playback)"
        case .bingo:
            let level = switch settings.bingoLevel {
            case .beginner: String(localized: "settings.bingo.level.beginner")
            case .expert: String(localized: "settings.bingo.level.expert")
            }
            return "\(String(localized: "settings.mode.bingo")) · \(level)"
        }
    }

    /// Release year of the current song for the revealed card, or «—» when it is unknown.
    var revealedYear: String {
        currentSong?.releaseYear.map(String.init) ?? "—"
    }

    /// Length of the whole current song for the revealed card, when it is known.
    var revealedDurationText: String? {
        (viewData.round?.songDuration ?? currentSong?.duration).map { Self.formatted(seconds: Int($0)) }
    }

    fileprivate static func message(for error: GamePlaybackError) -> String {
        switch error {
        case .subscriptionRequired: String(localized: "game.playback.subscriptionRequired")
        case .notAuthorized: String(localized: "game.playback.notAuthorized")
        case .unsupportedProvider: String(localized: "game.playback.unsupportedProvider")
        case .unavailable: String(localized: "game.playback.unavailable")
        }
    }
}
