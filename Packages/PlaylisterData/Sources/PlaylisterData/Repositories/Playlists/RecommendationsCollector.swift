import Foundation

/// Collects the recommended playlists from the pages of a catalogue search: keeps those whose name contains the
/// term, ignoring case and accents, until it has `limits.recommendations` of them or has read
/// `limits.recommendationsSearch` results. Internal and free of any provider SDK, so it is tested on its own.
struct RecommendationsCollector<Item> {
    private let term: String
    private let limits: PlaylistsLimits
    private let name: (Item) -> String

    /// Playlists that contain the term, in the order the search returned them.
    private(set) var items: [Item] = []
    /// Search results read so far, matching or not.
    private(set) var readCount = 0

    init(term: String, limits: PlaylistsLimits, name: @escaping (Item) -> String) {
        self.term = term
        self.limits = limits
        self.name = name
    }

    /// `true` once there are enough recommended playlists or the search has been read as far as allowed.
    var isComplete: Bool {
        items.count >= limits.recommendations || readCount >= limits.recommendationsSearch
    }

    /// Reads the results of one page, in order, until the collector is complete.
    mutating func add(_ page: [Item]) {
        for item in page {
            guard !isComplete else { return }
            readCount += 1
            if name(item).localizedStandardContains(term) {
                items.append(item)
            }
        }
    }
}
