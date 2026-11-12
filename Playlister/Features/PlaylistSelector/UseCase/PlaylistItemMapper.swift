import Foundation
import PlaylisterData

/// Maps a playlist of the Playlists repository out of the PlaylisterData types. Shared by the use cases of
/// PlaylistSelector, so every section shows its playlists the same way.
enum PlaylistItemMapper {
    static func playlist(from item: any PlaylistsItemProtocol) -> PlaylistSelectorViewData.Playlist {
        PlaylistSelectorViewData.Playlist(
            id: item.id,
            name: item.name,
            curatorName: item.curatorName,
            covers: item.artworkURL.map { [$0] } ?? []
        )
    }
}
