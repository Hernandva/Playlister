import Foundation
import MusicKit

/// Apple Music songs. Internal: the app only sees `SongRepositoryProtocol`.
/// Reads the first page of the playlist's songs through the Apple Music API (`AppleMusicAPIClient`) in one request,
/// which already brings each song's web artwork, and picks random ones among those with artwork.
struct AppleMusicSongService: SongServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400
    /// Songs read from the playlist: the most the API returns per page.
    private static let songsLimit = 100
    /// Library playlist identifiers start with it; catalogue ones start with «pl.».
    private static let libraryPlaylistIDPrefix = "p."

    private let client = AppleMusicAPIClient()

    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO {
        guard request.provider == .appleMusic else {
            throw SongError.unsupportedProvider(request.provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw SongError.notAuthorized
        }
        do {
            let page: AppleMusicPageDAO<AppleMusicSongAttributesDAO> = try await client.get(
                try await songsPath(of: request.playlistID),
                query: [URLQueryItem(name: "limit", value: "\(Self.songsLimit)")]
            )
            let songs = page.data.compactMap { SongItemDAO(song: $0, artworkSide: Self.artworkSide) }
            let picked = RandomSongPicker.pick(songs, count: request.count)
            return SongResponseDAO(provider: .appleMusic, items: picked)
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
