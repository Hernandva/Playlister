import Foundation
import MusicKit

/// Apple Music songs. Internal: the app only sees `SongRepositoryProtocol`.
/// Reads the first page of the playlist's songs through the Apple Music API (`AppleMusicAPIClient`) in one request,
/// which already brings each song's web artwork, and picks random ones among those with artwork. It also lists the
/// playlist's songs one page at a time.
struct AppleMusicSongService: SongServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400
    /// Side, in pixels, of the artwork of a listed song: shown at 48 pt.
    private static let listArtworkSide = 150
    /// Songs read from the playlist: the most the API returns per page.
    private static let songsLimit = 100
    /// Library playlist identifiers start with it; catalogue ones start with «pl.».
    private static let libraryPlaylistIDPrefix = "p."

    private let client = AppleMusicAPIClient()

    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO {
        try checkAccess(for: request.provider)
        return try await mappingErrors {
            let page: AppleMusicPageDAO<AppleMusicSongAttributesDAO> = try await client.get(
                try await songsPath(of: request.playlistID),
                query: [URLQueryItem(name: "limit", value: "\(Self.songsLimit)")]
            )
            let songs = page.data.compactMap { SongItemDAO(song: $0, artworkSide: Self.artworkSide) }
            let picked = RandomSongPicker.pick(songs, count: request.count)
            return SongResponseDAO(provider: .appleMusic, items: picked)
        }
    }

    /// One page of the playlist's songs, in their order. A next page is announced by the API's `next`.
    func fetchSongs(_ request: PlaylistSongsRequestDAO) async throws -> PlaylistSongsResponseDAO {
        try checkAccess(for: request.provider)
        return try await mappingErrors {
            let page: AppleMusicPageDAO<AppleMusicSongAttributesDAO> = try await client.get(
                try await songsPath(of: request.playlistID),
                query: [
                    URLQueryItem(name: "limit", value: "\(request.limit)"),
                    URLQueryItem(name: "offset", value: "\(request.offset)")
                ]
            )
            return PlaylistSongsResponseDAO(
                provider: .appleMusic,
                items: page.data.compactMap { PlaylistSongItemDAO(song: $0, artworkSide: Self.listArtworkSide) },
                total: page.meta?.total,
                hasMore: page.next != nil
            )
        }
    }

    private func checkAccess(for provider: MusicProvider) throws {
        guard provider == .appleMusic else {
            throw SongError.unsupportedProvider(provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw SongError.notAuthorized
        }
    }

    /// An unknown playlist (API 404) throws `SongError.playlistNotFound`, a cancellation goes through and any other
    /// failure throws `SongError.unavailable`.
    private func mappingErrors<Result: Sendable>(_ work: () async throws -> Result) async throws -> Result {
        do {
            return try await work()
        } catch let error as MusicDataRequest.Error where error.status == 404 {
            throw SongError.playlistNotFound
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw SongError.unavailable
        }
    }

    /// `me/library/playlists/{id}/tracks` for a library playlist, `catalog/{storefront}/playlists/{id}/tracks`
    /// for a catalogue one.
    private func songsPath(of playlistID: String) async throws -> String {
        if playlistID.hasPrefix(Self.libraryPlaylistIDPrefix) {
            return "me/library/playlists/\(playlistID)/tracks"
        }
        return "catalog/\(try await client.storefront())/playlists/\(playlistID)/tracks"
    }
}
