import Foundation

/// Picks random songs of a playlist. Internal and free of any provider SDK, so it is tested on its own.
enum RandomSongPicker {
    /// Up to `count` different songs, at random. All of them when the playlist has `count` or fewer.
    static func pick<Song>(_ songs: [Song], count: Int) -> [Song] {
        Array(songs.shuffled().prefix(max(count, 0)))
    }
}
