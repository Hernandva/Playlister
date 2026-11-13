import Foundation
import MusicKit

/// Apple Music player. Internal: the app only sees `PlayerRepositoryProtocol`.
/// Looks the song up by its identifier and plays it with MusicKit's `ApplicationMusicPlayer`, which plays
/// inside the app and leaves the Music app's queue untouched. Catalogue songs need an Apple Music subscription.
/// Pass the song's `catalogID` when it has one: a library id (`i.…`) is only found when the song is in the device
/// library, and a song added to a playlist is not always added to the library.
struct AppleMusicPlayerService: PlayerServiceProtocol {
    /// Library song identifiers start with it; catalogue ones are numbers.
    private static let librarySongIDPrefix = "i."

    func play(_ request: PlayerRequestDAO) async throws -> PlayerResponseDAO {
        try checkAccess(for: request.provider)
        let isLibrarySong = request.songID.hasPrefix(Self.librarySongIDPrefix)
        if !isLibrarySong {
            try await checkSubscription()
        }
        let song = try await mappingErrors {
            isLibrarySong ? try await librarySong(id: request.songID) : try await catalogSong(id: request.songID)
        }
        guard let song else {
            throw PlayerError.songNotFound
        }
        let player = ApplicationMusicPlayer.shared
        try await mappingErrors {
            player.queue = [song]
            try await player.prepareToPlay()
            if request.startTime > 0 {
                player.playbackTime = request.startTime
            }
            try await player.play()
        }
        return PlayerResponseDAO(provider: .appleMusic, songID: request.songID, duration: song.duration)
    }

    func pause() async {
        ApplicationMusicPlayer.shared.pause()
    }

    func resume() async throws {
        let player = ApplicationMusicPlayer.shared
        try await mappingErrors {
            try await player.play()
        }
    }

    func stop() async {
        let player = ApplicationMusicPlayer.shared
        player.stop()
        player.queue = []
    }

    func playbackTime() async -> TimeInterval {
        ApplicationMusicPlayer.shared.playbackTime
    }

    func status() async -> PlaybackStatus {
        switch ApplicationMusicPlayer.shared.state.playbackStatus {
        case .playing, .seekingForward, .seekingBackward: .playing
        case .paused, .interrupted: .paused
        case .stopped: .stopped
        @unknown default: .stopped
        }
    }

    private func checkAccess(for provider: MusicProvider) throws {
        guard provider == .appleMusic else {
            throw PlayerError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw PlayerError.notAuthorized
        }
    }

    /// Without an active subscription MusicKit cannot play catalogue songs.
    private func checkSubscription() async throws {
        let subscription: MusicSubscription
        do {
            subscription = try await MusicSubscription.current
        } catch {
            throw PlayerError.unavailable
        }
        guard subscription.canPlayCatalogContent else {
            throw PlayerError.subscriptionRequired
        }
    }

    private func catalogSong(id: String) async throws -> Song? {
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
        return try await request.response().items.first
    }

    private func librarySong(id: String) async throws -> Song? {
        var request = MusicLibraryRequest<Song>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        return try await request.response().items.first
    }

    /// A cancellation goes through and any other failure throws `PlayerError.unavailable`.
    private func mappingErrors<Result: Sendable>(_ work: () async throws -> Result) async throws -> Result {
        do {
            return try await work()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PlayerError.unavailable
        }
    }
}
