import Foundation

/// Wire format of the Playlists response. Internal to PlaylisterData: the app only sees PlaylistsResponseProtocol.
struct PlaylistsResponseDAO: Decodable, Sendable, PlaylistsResponseProtocol {}
