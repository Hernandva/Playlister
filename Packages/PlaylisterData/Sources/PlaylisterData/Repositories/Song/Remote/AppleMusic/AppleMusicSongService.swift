import Foundation
import MusicKit

/// Apple Music songs. Internal: the app only sees `SongRepositoryProtocol`.
/// Wraps MusicKit: finds the playlist in the library or in the catalogue and reads the first batch of its songs.
/// Those songs may come with little more than their identifier, so it picks `count` of them at random and looks only
/// those up by identifier to get their artwork.
struct AppleMusicSongService: SongServiceProtocol {
    /// Side, in pixels, of the artwork URLs.
    private static let artworkSide = 400
    /// Library playlist identifiers start with it; catalogue ones start with «pl.».
    private static let libraryPlaylistIDPrefix = "p."
    /// Library song identifiers start with it; catalogue ones are numbers.
    private static let librarySongIDPrefix = "i."

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
            let picked = RandomSongPicker.pick(tracks, count: request.count)
            Self.log("playlist \(request.playlistID): \(tracks.count) songs in the first batch")
            Self.log("picked: \(picked.map { "\($0.id.rawValue) (artwork: \(Self.scheme(of: $0.artwork)))" })")
            let songs = try await findSongs(ids: picked.map(\.id))
            Self.log("found: \(songs.map { "\($0.id.rawValue) (artwork: \(Self.scheme(of: $0.artwork)))" })")
            let items = songs.compactMap(Self.item(from:))
            Self.log("returned \(items.count) covers")
            return SongResponseDAO(provider: .appleMusic, items: items)
        } catch let error as SongError {
            Self.log("failed: \(error)")
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Self.log("failed: \(error)")
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
        Self.log("library ids: \(libraryIDs.map(\.rawValue)), catalog ids: \(catalogIDs.map(\.rawValue))")
        async let librarySongs = findLibrarySongs(ids: libraryIDs)
        async let catalogSongs = findCatalogSongs(ids: catalogIDs)
        let (library, catalog) = try await (librarySongs, catalogSongs)
        Self.log("library request found \(library.count), catalog request found \(catalog.count)")
        return library + catalog
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

    /// Debug builds only: one line per step of `fetchRandomSongs(_:)`, to see why a playlist gets no covers.
    private static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        debugPrint("[Songs] \(message())")
        #endif
    }

    /// Scheme of an artwork's URL (`https`, `musicKit`…), or `none` when there is no artwork. For the debug log.
    private static func scheme(of artwork: Artwork?) -> String {
        artwork?.url(width: artworkSide, height: artworkSide)?.scheme ?? "none"
    }

    /// Only web URLs are kept: library artwork can use a MusicKit scheme that `AsyncImage` cannot load.
    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: artworkSide, height: artworkSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
