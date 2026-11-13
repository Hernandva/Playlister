@testable import PlaylisterData
import Foundation
import Testing

private struct PlayerRequest: PlayerRequestProtocol {
    let provider: MusicProvider
    let songID: String
    let startTime: TimeInterval
}

private final class FakePlayerService: PlayerServiceProtocol, @unchecked Sendable {
    let error: PlayerError?
    private(set) var receivedRequest: PlayerRequestDAO?
    private(set) var currentStatus: PlaybackStatus = .stopped

    init(error: PlayerError? = nil) {
        self.error = error
    }

    func play(_ request: PlayerRequestDAO) async throws -> PlayerResponseDAO {
        receivedRequest = request
        if let error { throw error }
        currentStatus = .playing
        return PlayerResponseDAO(provider: request.provider, songID: request.songID, duration: 210)
    }

    func pause() async {
        currentStatus = .paused
    }

    func resume() async throws {
        if let error { throw error }
        currentStatus = .playing
    }

    func stop() async {
        currentStatus = .stopped
    }

    func playbackTime() async -> TimeInterval {
        42
    }

    func status() async -> PlaybackStatus {
        currentStatus
    }
}

struct PlayerRepositoryTests {
    private static let request = PlayerRequest(provider: .appleMusic, songID: "1440857781", startTime: 30)

    @Test func forwardsThePlayRequestToTheProviderPlayer() async throws {
        let service = FakePlayerService()
        let repository = PlayerRepository(services: [.appleMusic: service])

        let response = try await repository.play(Self.request)

        #expect(service.receivedRequest == PlayerRequestDAO(provider: .appleMusic, songID: "1440857781", startTime: 30))
        #expect(response.songID == "1440857781")
        #expect(response.duration == 210)
        #expect(try await repository.status(provider: .appleMusic) == .playing)
    }

    @Test func drivesThePlayerOfTheProvider() async throws {
        let repository = PlayerRepository(services: [.appleMusic: FakePlayerService()])
        _ = try await repository.play(Self.request)

        try await repository.pause(provider: .appleMusic)
        #expect(try await repository.status(provider: .appleMusic) == .paused)
        try await repository.resume(provider: .appleMusic)
        #expect(try await repository.status(provider: .appleMusic) == .playing)
        #expect(try await repository.playbackTime(provider: .appleMusic) == 42)
        try await repository.stop(provider: .appleMusic)
        #expect(try await repository.status(provider: .appleMusic) == .stopped)
    }

    @Test func forwardsTheErrorOfTheProviderPlayer() async {
        let repository = PlayerRepository(services: [.appleMusic: FakePlayerService(error: .subscriptionRequired)])
        await #expect(throws: PlayerError.subscriptionRequired) {
            try await repository.play(Self.request)
        }
    }

    @Test func throwsForAProviderWithoutPlayer() async {
        let repository = PlayerRepository(services: [.appleMusic: FakePlayerService()])
        let request = PlayerRequest(provider: .spotify, songID: "4uLU6hMCjMI75M1A2tKUQC", startTime: 0)
        await #expect(throws: PlayerError.unsupportedProvider(.spotify)) {
            try await repository.play(request)
        }
        await #expect(throws: PlayerError.unsupportedProvider(.spotify)) {
            try await repository.stop(provider: .spotify)
        }
    }
}
