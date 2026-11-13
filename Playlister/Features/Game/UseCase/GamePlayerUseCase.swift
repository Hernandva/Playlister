import Foundation
import PlaylisterData

/// Why a song could not be played, for the view model to explain it.
enum GamePlaybackError: Error, Equatable {
    /// The account cannot play the song, e.g. Apple Music without a subscription.
    case subscriptionRequired
    /// The user has not given the app access to the music service.
    case notAuthorized
    /// The music service has no player in the app yet (Spotify).
    case unsupportedProvider
    /// The song is missing or the player could not start.
    case unavailable
}

protocol GamePlayerUseCaseProtocol: Sendable {
    /// Plays the song as the settings say: a clip from the beginning or from a random point, or the whole song.
    /// Returns where it started. Throws `GamePlaybackError`.
    func play(
        song: GameViewData.Song,
        settings: GameViewData.Settings,
        provider: MusicProvider
    ) async throws -> GameViewData.Round
    /// Pauses the song that is playing at its current time.
    func pause(provider: MusicProvider) async
    /// Plays the paused song again from where it was paused. Throws `GamePlaybackError`.
    func resume(provider: MusicProvider) async throws
    /// Stops the song that is playing, e.g. when the user leaves the game.
    func stop(provider: MusicProvider) async
}

/// Request sent to the Player repository: the song and where it starts.
struct PlayGameSongRequest: PlayerRequestProtocol {
    let provider: MusicProvider
    let songID: String
    let startTime: TimeInterval
}

/// Plays, pauses, resumes and stops the game's songs through the Player repository public API.
struct GamePlayerUseCase: GamePlayerUseCaseProtocol {
    private let repository: any PlayerRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolvePlayerRepository()
    }

    func play(
        song: GameViewData.Song,
        settings: GameViewData.Settings,
        provider: MusicProvider
    ) async throws -> GameViewData.Round {
        let request = PlayGameSongRequest(
            provider: provider,
            songID: song.playbackID,
            startTime: Self.startTime(of: song, settings: settings)
        )
        let response = try await mappingErrors {
            try await repository.play(request)
        }
        return GameViewData.Round(startTime: request.startTime, songDuration: response.duration ?? song.duration)
    }

    func pause(provider: MusicProvider) async {
        // A provider without a player has nothing playing, so there is nothing to pause.
        try? await repository.pause(provider: provider)
    }

    func resume(provider: MusicProvider) async throws {
        try await mappingErrors {
            try await repository.resume(provider: provider)
        }
    }

    func stop(provider: MusicProvider) async {
        // A provider without a player has nothing playing, so there is nothing to stop.
        try? await repository.stop(provider: provider)
    }

    /// 0, unless a clip starts at random: then any second that leaves the whole clip before the end of the song.
    /// Without the song's length it starts at 0.
    static func startTime(of song: GameViewData.Song, settings: GameViewData.Settings) -> TimeInterval {
        guard settings.playback == .clip, settings.clipStart == .random, let duration = song.duration else {
            return 0
        }
        let latestStart = duration - TimeInterval(settings.clipSeconds)
        return latestStart > 0 ? TimeInterval.random(in: 0...latestStart) : 0
    }

    /// Turns an error of the Player repository into the game's `GamePlaybackError`; others go through.
    private func mappingErrors<Result: Sendable>(_ work: () async throws -> Result) async throws -> Result {
        do {
            return try await work()
        } catch let error as PlayerError {
            throw GamePlaybackError(error)
        }
    }
}

private extension GamePlaybackError {
    init(_ error: PlayerError) {
        switch error {
        case .subscriptionRequired: self = .subscriptionRequired
        case .notAuthorized: self = .notAuthorized
        case .unsupportedProvider: self = .unsupportedProvider
        case .songNotFound, .unavailable: self = .unavailable
        }
    }
}
