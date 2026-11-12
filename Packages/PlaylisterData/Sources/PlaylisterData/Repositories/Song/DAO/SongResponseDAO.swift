import Foundation

/// Wire format of the Song response. Internal to PlaylisterData: the app only sees SongResponseProtocol.
struct SongResponseDAO: Decodable, Sendable, SongResponseProtocol {}
