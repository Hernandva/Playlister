import Foundation

/// What kind of artist sings the song. Internal to PlaylisterData: the app only sees ArtistResponseProtocol.
struct ArtistResponseDAO: Sendable, Equatable, ArtistResponseProtocol {
    let artistName: String?
    let kind: ArtistKind
    let countryCodes: [String]
    /// MusicBrainz identifier of the artist, to ask Wikidata for its countries. Never leaves the package.
    let musicBrainzID: String?

    init(artistName: String?, kind: ArtistKind, countryCodes: [String] = [], musicBrainzID: String? = nil) {
        self.artistName = artistName
        self.kind = kind
        self.countryCodes = countryCodes
        self.musicBrainzID = musicBrainzID
    }

    init(_ artist: MusicBrainzArtistDAO) {
        self.init(
            artistName: artist.name,
            kind: ArtistKind(musicBrainzType: artist.type),
            countryCodes: ArtistCountryCode.valid([artist.country].compactMap { $0 }),
            musicBrainzID: artist.id
        )
    }

    /// The same answer with `codes` as its countries.
    func with(countryCodes codes: [String]) -> ArtistResponseDAO {
        ArtistResponseDAO(artistName: artistName, kind: kind, countryCodes: codes, musicBrainzID: musicBrainzID)
    }
}

/// Keeps the codes that are current ISO 3166-1 countries. MusicBrainz also uses `XW` (worldwide), `XE` (Europe) or
/// gone countries such as `SU`, which have no flag: those count as unknown, so Wikidata is asked instead.
enum ArtistCountryCode {
    private static let isoRegions = Set(Locale.Region.isoRegions.map(\.identifier))

    static func valid(_ codes: [String]) -> [String] {
        var seen = Set<String>()
        return codes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { $0.count == 2 && isoRegions.contains($0) && seen.insert($0).inserted }
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
    /// MusicBrainz identifier (MBID), a UUID.
    let id: String?
    let name: String
    /// «Person», «Group», «Orchestra», «Choir», «Character» or «Other»; missing when nobody has said.
    let type: String?
    /// ISO 3166-1 code of the artist's country, when MusicBrainz has one; often missing when only a city is known.
    let country: String?
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
