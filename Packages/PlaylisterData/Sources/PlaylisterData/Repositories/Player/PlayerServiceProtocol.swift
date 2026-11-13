import Foundation

/// Player of one music service: the common contract every provider implements in `Remote/<Provider>/`
/// and registers in `PlayerRepository.init()`. Internal: the app only sees `PlayerRepositoryProtocol`.
///
/// Today only Apple Music has one (`AppleMusicPlayerService`, MusicKit's `ApplicationMusicPlayer`).
/// A Spotify player (e.g. the Spotify iOS SDK's App Remote) conforms to it and is added to
/// `PlayerRepository.init()` under `.spotify`; nothing above the repository changes.
///
/// Every method is `async`, so each player can hop to the actor or queue its SDK needs. They throw `PlayerError`.
protocol PlayerServiceProtocol: Sendable {
    /// Replaces whatever is playing with the song and plays it from `request.startTime`.
    func play(_ request: PlayerRequestDAO) async throws -> PlayerResponseDAO
    /// Pauses the song at its current time.
    func pause() async
    /// Plays the paused song again from where it was paused.
    func resume() async throws
    /// Stops playback and empties the player.
    func stop() async
    /// Current time of the song that is loaded, in seconds; 0 when nothing is.
    func playbackTime() async -> TimeInterval
    func status() async -> PlaybackStatus
}
