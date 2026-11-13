import Foundation

/// What kind of artist sings the song. Internal to PlaylisterData: the app only sees ArtistResponseProtocol.
struct ArtistResponseDAO: Sendable, Equatable, ArtistResponseProtocol {
    let artistName: String?
    let kind: ArtistKind

    init(artistName: String?, kind: ArtistKind) {
        self.artistName = artistName
        self.kind = kind
    }

    init(_ artist: MusicBrainzArtistDAO) {
        self.init(artistName: artist.name, kind: ArtistKind(musicBrainzType: artist.type))
    }
}

/// Answer of `GET /ws/2/isrc/{isrc}?inc=artist-credits`. Internal.
struct MusicBrainzISRCResponseDAO: Decodable, Sendable {
    let recordings: [MusicBrainzRecordingDAO]

    /// First artist credited on the first recording: the main artist of «A feat. B».
    var mainArtist: MusicBrainzArtistDAO? {
        recordings.lazy.compactMap { $0.artistCredit?.first?.artist }.first
    }
}

struct MusicBrainzRecordingDAO: Decodable, Sendable {
    let artistCredit: [MusicBrainzArtistCreditDAO]?

    enum CodingKeys: String, CodingKey {
        case artistCredit = "artist-credit"
    }
}

struct MusicBrainzArtistCreditDAO: Decodable, Sendable {
    let artist: MusicBrainzArtistDAO
}

/// An artist of MusicBrainz. `score` (0…100) only comes in searches.
struct MusicBrainzArtistDAO: Decodable, Sendable {
    let name: String
    /// «Person», «Group», «Orchestra», «Choir», «Character» or «Other»; missing when nobody has said.
    let type: String?
    let score: Int?
}

/// Answer of `GET /ws/2/artist?query=…`. Internal.
struct MusicBrainzArtistSearchResponseDAO: Decodable, Sendable {
    let artists: [MusicBrainzArtistDAO]
}

extension ArtistKind {
    init(musicBrainzType type: String?) {
        switch type {
        case "Person": self = .solo
        case "Group", "Orchestra", "Choir": self = .group
        default: self = .unknown
        }
    }
}
