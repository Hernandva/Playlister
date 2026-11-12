import Foundation
import MusicKit

/// Turns MusicKit playlists into `PlaylistsItemDAO`s: loads their songs to count them and to pick the covers.
enum AppleMusicPlaylistMapper {
    /// Covers shown in the 2×2 mosaic.
    private static let coverCount = 4
    /// Side, in pixels, of the cover URLs.
    private static let coverSide = 400
    /// Songs read per playlist at most, so very long playlists do not page forever.
    private static let maxSongs = 1000

    /// Maps every playlist, in parallel, keeping their order.
    static func items(from playlists: [Playlist]) async throws -> [PlaylistsItemDAO] {
        try await withThrowingTaskGroup(of: (Int, PlaylistsItemDAO).self) { group in
            for (index, playlist) in playlists.enumerated() {
                group.addTask { (index, try await item(from: playlist)) }
            }
            var items = [PlaylistsItemDAO?](repeating: nil, count: playlists.count)
            for try await (index, item) in group {
                items[index] = item
            }
            return items.compactMap { $0 }
        }
    }

    private static func item(from playlist: Playlist) async throws -> PlaylistsItemDAO {
        let detailed = try await playlist.with([.tracks])
        let tracks = try await allTracks(of: detailed)
        return PlaylistsItemDAO(
            id: playlist.id.rawValue,
            name: playlist.name,
            songCount: tracks.count,
            coverURLs: coverURLs(of: tracks, playlistArtwork: playlist.artwork)
        )
    }

    /// Every song of the playlist, following the next batches up to `maxSongs`.
    private static func allTracks(of playlist: Playlist) async throws -> [Track] {
        guard var batch = playlist.tracks else { return [] }
        var tracks = Array(batch)
        while batch.hasNextBatch, tracks.count < maxSongs, let next = try await batch.nextBatch() {
            tracks += next
            batch = next
        }
        return tracks
    }

    /// Up to four covers from different albums, or the playlist's own artwork when there are fewer.
    /// Only web URLs are kept: library artwork can use a MusicKit scheme that `AsyncImage` cannot load.
    private static func coverURLs(of tracks: [Track], playlistArtwork: Artwork?) -> [URL] {
        var albums = Set<String>()
        var urls: [URL] = []
        for track in tracks where urls.count < coverCount {
            guard let url = webURL(of: track.artwork) else { continue }
            if albums.insert(track.albumTitle ?? url.absoluteString).inserted {
                urls.append(url)
            }
        }
        if urls.count < coverCount, let playlistURL = webURL(of: playlistArtwork) {
            return [playlistURL]
        }
        return urls
    }

    private static func webURL(of artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(width: coverSide, height: coverSide),
              url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
