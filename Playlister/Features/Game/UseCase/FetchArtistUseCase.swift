import Foundation
import PlaylisterData

protocol FetchArtistUseCaseProtocol: Sendable {
    /// Whether the song's main artist is a solo artist or a group, and its countries.
    func execute(song: GameViewData.Song) async throws -> GameViewData.Artist
}

/// Request sent to the Artist repository: the song's artist and, when it has one, its ISRC.
struct ArtistRequest: ArtistRequestProtocol {
    let artistName: String
    let isrc: String?
}

/// Asks the Artist repository public API (MusicBrainz, and Wikidata for a missing country) who sings the song.
struct FetchArtistUseCase: FetchArtistUseCaseProtocol {
    private let repository: any ArtistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolveArtistRepository()
    }

    func execute(song: GameViewData.Song) async throws -> GameViewData.Artist {
        let response = try await repository.fetchKind(ArtistRequest(artistName: song.artist, isrc: song.isrc))
        return GameViewData.Artist(kind: Self.kind(response.kind), countryCodes: response.countryCodes)
    }

    private static func kind(_ kind: ArtistKind) -> GameViewData.ArtistKind? {
        switch kind {
        case .solo: .solo
        case .group: .group
        case .unknown: nil
        }
    }
}
