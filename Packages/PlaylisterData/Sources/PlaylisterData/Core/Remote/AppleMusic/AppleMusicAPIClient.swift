import Foundation
import MusicKit

/// Calls the Apple Music API (`https://api.music.apple.com/v1/`) through MusicKit's `MusicDataRequest`, which adds
/// the developer and user tokens. Internal: shared by the Apple Music services of every repository.
///
/// It is not `NetworkClient` because only MusicKit can sign these requests. Use it when the API returns what
/// MusicKit's own requests do not, e.g. web artwork for the user's library (`MusicLibraryRequest` returns
/// `musicKit://` artwork that `AsyncImage` cannot load).
struct AppleMusicAPIClient: Sendable {
    private static let baseURL = "https://api.music.apple.com/v1/"

    /// GETs `path` (e.g. `me/library/playlists`) with `query` and decodes the JSON response.
    func get<Response: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw URLError(.badURL)
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let response = try await MusicDataRequest(urlRequest: URLRequest(url: url)).response()
        return try JSONDecoder().decode(Response.self, from: response.data)
    }

    /// Storefront (country) of the user, e.g. `es`, needed by every catalogue path.
    func storefront() async throws -> String {
        try await MusicDataRequest.currentCountryCode
    }
}
