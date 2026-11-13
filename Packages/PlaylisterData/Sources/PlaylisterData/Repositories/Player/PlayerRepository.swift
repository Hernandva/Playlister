import Foundation

/// Public API of the Player repository. Features depend on this protocol, never on the concrete class.
/// Every call names the provider whose player it drives. Calls throw `PlayerError`.
public protocol PlayerRepositoryProtocol: Sendable {
    /// Replaces whatever is playing with the song and plays it from `request.startTime`.
    func play(_ request: some PlayerRequestProtocol) async throws -> any PlayerResponseProtocol
    /// Pauses the song at its current time.
    func pause(provider: MusicProvider) async throws
    /// Plays the paused song again from where it was paused.
    func resume(provider: MusicProvider) async throws
    /// Stops playback and empties the player.
    func stop(provider: MusicProvider) async throws
    /// Current time of the song that is loaded, in seconds; 0 when nothing is.
    func playbackTime(provider: MusicProvider) async throws -> TimeInterval
    func status(provider: MusicProvider) async throws -> PlaybackStatus
}

/// Public entry point of playback: forwards each call to the player of its provider.
/// Flow: PlayerRequestProtocol -> PlayerRequestDAO -> provider player -> PlayerResponseDAO -> PlayerResponseProtocol.
public final class PlayerRepository: PlayerRepositoryProtocol {
    private let services: [MusicProvider: any PlayerServiceProtocol]

    public convenience init() {
        self.init(services: MusicProvider.appleMusicServices(AppleMusicPlayerService()))
    }

    /// Lets tests inject fake players.
    init(services: [MusicProvider: any PlayerServiceProtocol]) {
        self.services = services
    }

    public func play(_ request: some PlayerRequestProtocol) async throws -> any PlayerResponseProtocol {
        try await service(for: request.provider).play(PlayerRequestDAO(request))
    }

    public func pause(provider: MusicProvider) async throws {
        try await service(for: provider).pause()
    }

    public func resume(provider: MusicProvider) async throws {
        try await service(for: provider).resume()
    }

    public func stop(provider: MusicProvider) async throws {
        try await service(for: provider).stop()
    }

    public func playbackTime(provider: MusicProvider) async throws -> TimeInterval {
        try await service(for: provider).playbackTime()
    }

    public func status(provider: MusicProvider) async throws -> PlaybackStatus {
        try await service(for: provider).status()
    }

    private func service(for provider: MusicProvider) throws -> any PlayerServiceProtocol {
        guard let service = services[provider] else {
            throw PlayerError.unsupportedProvider(provider)
        }
        return service
    }
}
