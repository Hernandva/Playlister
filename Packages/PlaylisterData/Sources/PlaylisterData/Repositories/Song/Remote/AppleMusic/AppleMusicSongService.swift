import Foundation
import MusicKit

/// Apple Music songs. Internal: the app only sees `SongRepositoryProtocol`.
/// Wraps MusicKit: finds the playlist in the library or in the catalogue and reads the first batch of its songs.
/// Those songs may come with little more than their identifier, so it looks a few random ones up by identifier to
/// get their artwork, then picks the final ones with `RandomSongPicker`.
struct AppleMusicSongService: SongServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400
    /// Library playlist identifiers start with it; catalogue ones start with «pl.».
    private static let libraryPlaylistIDPrefix = "p."
    /// Library song identifiers start with it; catalogue ones are numbers.
    private static let librarySongIDPrefix = "i."
    /// Random songs looked up per playlist, more than requested so songs from different albums and with artwork
    /// can still be picked.
    private static let candidatesPerSong = 3

    func fetchRandomSongs(_ request: SongRequestDAO) async throws -> SongResponseDAO {
        guard request.provider == .appleMusic else {
            throw SongError.unsupportedProvider(request.provider)
        }
        guard MusicAuthorization.currentStatus == .authorized else {
            throw SongError.notAuthorized
        }
        do {
            let playlist = try await findPlaylist(id: request.playlistID).with([.tracks])
            let candidates = (playlist.tracks ?? []).shuffled().prefix(request.count * Self.candidatesPerSong)
            let songs = try await findSongs(ids: candidates.map(\.id))
            let picked = RandomSongPicker.pick(
                songs,
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
        if id.hasPrefix(Self.libraryPlaylistIDPrefix) {
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

    /// Looks the songs up by identifier, with their full data and artwork: library songs in the library and catalogue
    /// songs in the catalogue, one request each and at the same time.
    private func findSongs(ids: [MusicItemID]) async throws -> [Song] {
        let libraryIDs = ids.filter { $0.rawValue.hasPrefix(Self.librarySongIDPrefix) }
        let catalogIDs = ids.filter { !$0.rawValue.hasPrefix(Self.librarySongIDPrefix) }
        async let librarySongs = findLibrarySongs(ids: libraryIDs)
        async let catalogSongs = findCatalogSongs(ids: catalogIDs)
        return try await librarySongs + catalogSongs
    }

    private func findLibrarySongs(ids: [MusicItemID]) async throws -> [Song] {
        guard !ids.isEmpty else { return [] }
        var request = MusicLibraryRequest<Song>()
        request.filter(matching: \.id, memberOf: ids)
        return try await Array(request.response().items)
    }

    private func findCatalogSongs(ids: [MusicItemID]) async throws -> [Song] {
        guard !ids.isEmpty else { return [] }
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: ids)
        return try await Array(request.response().items)
    }

    private static func item(from song: Song) -> SongItemDAO? {
        guard let url = webURL(of: song.artwork) else { return nil }
        return SongItemDAO(id: song.id.rawValue, title: song.title, artistName: song.artistName, artworkURL: url)
    }

    /// Only web URLs are kept: library artwork can use a MusicKit scheme that `AsyncImage` cannot load.
    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: artworkSide, height: artworkSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
