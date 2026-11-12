import Foundation

/// Songs of one music service. Internal: every provider has its own service in `Remote/<Provider>/`,
/// registered in `SongRepository.init()`.
protocol SongServiceProtocol: Sendable {
    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO
}
