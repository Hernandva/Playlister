import Foundation

/// Collects the recommended playlists from the pages of a catalogue search: keeps those the provider allows
/// (`isAllowed`) whose name contains the term, ignoring case and accents, until it has `limits.recommendations` of
/// them or has read `limits.recommendationsSearch` results. Results left out still count as read.
/// Internal and free of any provider SDK, so it is tested on its own.
struct RecommendationsCollector<Item> {
    private let term: String
    private let limits: PlaylistsLimits
    private let name: (Item) -> String
    private let isAllowed: (Item) -> Bool

    /// Playlists that contain the term, in the order the search returned them.
    private(set) var items: [Item] = []
    /// Search results read so far, matching or not.
    private(set) var readCount = 0

    /// - Parameters:
    ///   - name: Name of a result, compared with the term.
    ///   - isAllowed: `false` for results the provider leaves out whatever their name, e.g. editorial playlists.
    init(
        term: String,
        limits: PlaylistsLimits,
        name: @escaping (Item) -> String,
        isAllowed: @escaping (Item) -> Bool = { _ in true }
    ) {
        self.term = term
        self.limits = limits
        self.name = name
        self.isAllowed = isAllowed
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
            if isAllowed(item), name(item).localizedStandardContains(term) {
                items.append(item)
            }
        }
    }
}
