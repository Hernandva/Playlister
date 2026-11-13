import Foundation

/// The song whose artist is asked for. Internal to PlaylisterData: never exposed to the app.
struct ArtistRequestDAO: Sendable, Equatable {
    let artistName: String
    /// Upper-cased, `nil` when the song has none.
    let isrc: String?

    init(_ request: some ArtistRequestProtocol) {
        self.init(artistName: request.artistName, isrc: request.isrc)
    }

    init(artistName: String, isrc: String?) {
        self.artistName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = isrc?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.isrc = code?.isEmpty == false ? code : nil
    }

    /// The name without case or accents, so «ROSALÍA» and «Rosalía» are the same artist.
    var nameKey: String {
        artistName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// Query of `GET /ws/2/isrc/{isrc}`: the recordings with that ISRC and their artists.
struct MusicBrainzISRCQueryDAO: Encodable, Sendable {
    let inc = "artist-credits"
    let fmt = "json"
}

/// Query of `GET /ws/2/artist`: a Lucene search of artists by name, best match first.
struct MusicBrainzArtistSearchQueryDAO: Encodable, Sendable {
    let query: String
    let limit: Int
    let fmt = "json"

    init(name: String, limit: Int = 1) {
        // Quotes and backslashes would end the Lucene phrase.
        let phrase = name
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        self.query = "artist:\"\(phrase)\""
        self.limit = limit
    }
}
