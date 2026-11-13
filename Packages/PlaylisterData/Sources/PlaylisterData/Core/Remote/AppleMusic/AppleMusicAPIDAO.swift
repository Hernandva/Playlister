import Foundation

/// A page of Apple Music API resources: `{ "data": [ … ], "next": "…" }`. Internal.
struct AppleMusicPageDAO<Attributes: Decodable & Sendable>: Decodable, Sendable {
    let data: [AppleMusicResourceDAO<Attributes>]
    /// Path of the next page, when there is one.
    let next: String?
    /// Sent by some paths, e.g. the songs of a playlist, with the number of resources of every page together.
    let meta: AppleMusicPageMetaDAO?
}

/// `meta` of a page of the Apple Music API: `{ "total": 312 }`. Internal.
struct AppleMusicPageMetaDAO: Decodable, Sendable {
    let total: Int?
}

/// One Apple Music API resource: its `id`, its `type` («songs», «library-songs», «music-videos»…) and its
/// `attributes`, which the API may leave out. Internal.
struct AppleMusicResourceDAO<Attributes: Decodable & Sendable>: Decodable, Sendable {
    let id: String
    let type: String?
    let attributes: Attributes?
}

/// Artwork of an Apple Music API resource. Its `url` is a template with `{w}` and `{h}` placeholders. Internal.
struct AppleMusicArtworkDAO: Decodable, Sendable, Equatable {
    let url: String

    /// The artwork as a square web URL of `side` pixels, or `nil` when it is not a web URL.
    func url(side: Int) -> URL? {
        let filled = url
            .replacingOccurrences(of: "{w}", with: "\(side)")
            .replacingOccurrences(of: "{h}", with: "\(side)")
        guard let url = URL(string: filled), url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
