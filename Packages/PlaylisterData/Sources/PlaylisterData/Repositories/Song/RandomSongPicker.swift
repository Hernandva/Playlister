import Foundation

/// Picks random songs for a cover mosaic: only songs with artwork, at most one per album, up to `count`.
/// Internal and free of any provider SDK, so it is tested on its own.
enum RandomSongPicker {
    /// - Parameters:
    ///   - album: Album of a song, so two songs of the same album are not both picked. `nil` when unknown.
    ///   - artworkURL: Web artwork of a song, or `nil` when it has none: those songs are never picked.
    static func pick<Song>(
        _ songs: [Song],
        count: Int,
        album: (Song) -> String?,
        artworkURL: (Song) -> URL?
    ) -> [Song] {
        var albums = Set<String>()
        var picked: [Song] = []
        for song in songs.shuffled() where picked.count < count {
            guard let url = artworkURL(song) else { continue }
            if albums.insert(album(song) ?? url.absoluteString).inserted {
                picked.append(song)
            }
        }
        return picked
    }
}
