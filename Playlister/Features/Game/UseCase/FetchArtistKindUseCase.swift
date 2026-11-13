import Foundation
import PlaylisterData

protocol FetchArtistKindUseCaseProtocol: Sendable {
    /// Whether the song's main artist is a solo artist or a group, or `nil` when MusicBrainz does not know.
    func execute(song: GameViewData.Song) async throws -> GameViewData.ArtistKind?
}

/// Request sent to the Artist repository: the song's artist and, when it has one, its ISRC.
struct ArtistKindRequest: ArtistRequestProtocol {
    let artistName: String
    let isrc: String?
}

/// Asks the Artist repository public API (MusicBrainz) what kind of artist sings the song.
struct FetchArtistKindUseCase: FetchArtistKindUseCaseProtocol {
    private let repository: any ArtistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolveArtistRepository()
    }

    func execute(song: GameViewData.Song) async throws -> GameViewData.ArtistKind? {
        let response = try await repository.fetchKind(ArtistKindRequest(artistName: song.artist, isrc: song.isrc))
        switch response.kind {
        case .solo: return .solo
        case .group: return .group
        case .unknown: return nil
        }
    }
}
