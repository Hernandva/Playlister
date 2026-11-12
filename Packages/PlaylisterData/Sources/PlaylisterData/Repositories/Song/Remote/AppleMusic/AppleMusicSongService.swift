import Foundation
import MusicKit

/// Apple Music songs. Internal: the app only sees `SongRepositoryProtocol`.
/// Wraps MusicKit: finds the playlist in the library or in the catalogue, reads the first batch of its songs and
/// picks random ones with `RandomSongPicker`.
struct AppleMusicSongService: SongServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400
    /// Library playlist identifiers start with it; catalogue ones start with «pl.».
    private static let libraryIDPrefix = "p."

    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO {
        guard request.provider == .appleMusic else {
            throw SongError.unsupportedProvider(request.provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw SongError.notAuthorized
        }
        do {
            let playlist = try await findPlaylist(id: request.playlistID).with([.tracks])
            let tracks = Array(playlist.tracks ?? [])
            let picked = RandomSongPicker.pick(
                tracks,
                count: request.count,
                album: { $0.albumTitle },
                artworkURL: { Self.webURL(of: $0.artwork) }
            )
            return SongResponseDAO(provider: .appleMusic, items: picked.compactMap(Self.item(from:)))
        } catch let error as SongError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw SongError.unavailable
        }
    }

    private func findPlaylist(id: String) async throws -> Playlist {
        let itemID = MusicItemID(id)
        if id.hasPrefix(Self.libraryIDPrefix) {
            var request = MusicLibraryRequest<Playlist>()
            request.filter(matching: \.id, equalTo: itemID)
            if let playlist = try await request.response().items.first {
                return playlist
            }
        } else {
            let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: itemID)
            if let playlist = try await request.response().items.first {
                return playlist
            }
        }
        throw SongError.playlistNotFound
    }

    private static func item(from track: Track) -> SongItemDAO? {
        guard let url = webURL(of: track.artwork) else { return nil }
        return SongItemDAO(id: track.id.rawValue, title: track.title, artistName: track.artistName, artworkURL: url)
    }

    /// Only web URLs are kept: library artwork can use a MusicKit scheme that `AsyncImage` cannot load.
    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: artworkSide, height: artworkSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
