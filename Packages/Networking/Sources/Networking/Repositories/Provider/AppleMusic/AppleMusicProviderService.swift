import Foundation
import MusicKit

/// Apple Music data. Internal: the app only sees `ProviderRepositoryProtocol`.
protocol AppleMusicProviderServiceProtocol: ProviderServiceProtocol {}

/// Wraps MusicKit: reads the playlist the user played last in Apple Music, its song count and covers.
struct AppleMusicProviderService: AppleMusicProviderServiceProtocol {
    private static let maxCovers = 4
    private static let coverSide = 300

    func fetch(_ request: some ProviderRequestProtocol) async throws -> ProviderResponseDAO {
        guard request.provider == .appleMusic else {
            throw ProviderError.unsupportedProvider(request.provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw ProviderError.notAuthorized
        }
        do {
            return ProviderResponseDAO(provider: .appleMusic, playlist: try await lastPlayedPlaylist())
        } catch {
            throw ProviderError.unavailable
        }
    }
}

private extension AppleMusicProviderService {
    func lastPlayedPlaylist() async throws -> ProviderPlaylistDAO? {
        let recentlyPlayed = try await MusicRecentlyPlayedContainerRequest().response()
        let lastPlaylist = recentlyPlayed.items.lazy.compactMap { item -> Playlist? in
            if case .playlist(let playlist) = item { return playlist }
            return nil
        }.first
        guard let lastPlaylist else { return nil }
        let playlist = try await lastPlaylist.with([.tracks])
        let tracks = try await allTracks(startingWith: playlist.tracks)
        return ProviderPlaylistDAO(
            name: playlist.name,
            songCount: tracks.count,
            coverURLs: Self.coverURLs(of: playlist, tracks: tracks)
        )
    }

    /// MusicKit returns the tracks in batches: loads the rest so the song count is complete.
    func allTracks(startingWith firstBatch: MusicItemCollection<Track>?) async throws -> [Track] {
        guard var batch = firstBatch else { return [] }
        var tracks = Array(batch)
        while batch.hasNextBatch, let nextBatch = try await batch.nextBatch() {
            tracks.append(contentsOf: nextBatch)
            batch = nextBatch
        }
        return tracks
    }

    /// Covers of different albums, in playlist order; the playlist's own artwork when there are none.
    static func coverURLs(of playlist: Playlist, tracks: [Track]) -> [URL] {
        var covers: [URL] = []
        for track in tracks {
            guard let url = track.artwork?.url(width: coverSide, height: coverSide), !covers.contains(url) else {
                continue
            }
            covers.append(url)
            if covers.count == maxCovers { break }
        }
        if covers.isEmpty, let url = playlist.artwork?.url(width: coverSide, height: coverSide) {
            covers.append(url)
        }
        return covers
    }
}
