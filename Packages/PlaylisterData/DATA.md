# PlaylisterData — configuration

The `PlaylisterData` package is the data layer of the app: it owns every repository, whether its data comes from a
remote API (Alamofire) or from the device (`UserDefaults`). Features never know where the data comes from.
Humans and coding agents must follow this file; the `playlister-new-repo` skill keeps the
**Repository registry** below up to date. Do not remove the `codegen` markers.

## Rules

- **Alamofire** is the HTTP layer, and only `Core/Remote/NetworkClient.swift` imports it.
- The **Apple Music API** (`https://api.music.apple.com/v1/`) is the one exception: only MusicKit can sign its
  requests, so every call to it goes through `Core/Remote/AppleMusic/AppleMusicAPIClient.swift`, which uses
  `MusicDataRequest`. Its responses share the DAOs of `AppleMusicAPIDAO.swift` (page, resource, artwork template).
- **Apple Music data always comes from the API**, never from MusicKit's own requests (`MusicCatalog…Request`,
  `MusicLibraryRequest`): the API gives web artwork everywhere (`MusicLibraryRequest` gives `musicKit://` artwork
  that `AsyncImage` cannot load) and one shape of DAO for the catalogue and the library. MusicKit is used only for
  what the API cannot do: the permission (`MusicAuthorization`) and the subscription (`MusicSubscription`).
- Each repository lives in its own folder: `Sources/PlaylisterData/Repositories/<Name>/`.
- Data sources are split by where the data lives, both in `Core/` and inside each repository:
  - `Remote/`: whatever leaves the device, such as HTTP through `NetworkClient` or a provider SDK like MusicKit.
    Provider services go in `Remote/<Provider>/`.
  - `Local/`: storage on the device, such as `UserDefaults`.
  - `DAO/` stays at the root of the repository, because one DAO can serve both sources (e.g. a cached response).
- `UserDefaults` keys start with `playlisterData.` followed by the repository, e.g. `playlisterData.settings.spotify`.
- The app only sees **public** types: the repository API and the request/response protocols.
- Wire formats are **DAOs**, which are `internal`, so they never leave the package.

## Anatomy of a repository

Every new repository creates a public API that asks for a public data protocol, plus internal DAOs for the call and the response:

```
<Name>RequestProtocol  ->  <Name>RequestDAO  ->  (HTTP via NetworkClient)  ->  <Name>ResponseDAO  ->  <Name>ResponseProtocol
      public                  internal                                          internal                public
```

Example: `NewRequestProtocol -> NewRequestDAO -> NewResponseDAO -> NewResponseProtocol`.

```
Repositories/New/
├── NewRepository.swift          # public protocol NewRepositoryProtocol + public final class NewRepository
├── NewRequestProtocol.swift     # public: what the app must provide
├── NewResponseProtocol.swift    # public: what the app receives
├── DAO/
│   ├── NewRequestDAO.swift      # internal Encodable built from NewRequestProtocol
│   └── NewResponseDAO.swift     # internal Decodable that conforms to NewResponseProtocol
├── Remote/                      # only when it has its own remote source, e.g. Remote/AppleMusic/
└── Local/                       # only when it stores data on the device, e.g. NewStorage.swift
```

The generator creates the HTTP shape above, which calls `Core/Remote/NetworkClient` directly, so it adds no
`Remote/` or `Local/` folder. Add them by hand when the repository gets its own source.

### Configuration

Each repository declares its endpoints in a static configuration. It is created empty, to be filled in:

```swift
public static let configuration = RepositoryConfiguration(
    baseURL: "",          // e.g. "https://api.example.com/v1"
    serviceNames: []      // e.g. ["users", "users/search"]
)
```

Calls to a service that is not in `serviceNames`, or made while `baseURL` is empty, throw a `NetworkError`.

### Consuming a repository from a feature

`<Feature>Dependencies` injects `<Name>RepositoryProtocol`, and `<Feature>UseCase` calls `fetch(_:serviceName:)` with a type that conforms to `<Name>RequestProtocol`. It then maps the returned `<Name>ResponseProtocol` into `<Feature>ViewData`.

### Creating a repository

Use the `playlister-new-repo` skill, or run:

```
python3 scripts/codegen/new_repo.py --name <RepositoryName>
```

## Repository registry

<!-- codegen:repository-registry:start -->
| Repository | Public API | Folder |
|---|---|---|
| `Authorization` | `AuthorizationServiceProtocol` / `AuthorizationRepository` | `Sources/PlaylisterData/Repositories/Authorization/` |
| `Login` | `LoginServiceProtocol` / `LoginRepository` | `Sources/PlaylisterData/Repositories/Login/` |
| `LastPlaylist` | `LastPlaylistRepositoryProtocol` / `LastPlaylistRepository` | `Sources/PlaylisterData/Repositories/LastPlaylist/` |
| `Settings` | `SettingsRepositoryProtocol` / `SettingsRepository` | `Sources/PlaylisterData/Repositories/Settings/` |
| `Playlists` | `PlaylistsRepositoryProtocol` / `PlaylistsRepository` | `Sources/PlaylisterData/Repositories/Playlists/` |
| `Song` | `SongRepositoryProtocol` / `SongRepository` | `Sources/PlaylisterData/Repositories/Song/` |
| `Player` | `PlayerRepositoryProtocol` / `PlayerRepository` | `Sources/PlaylisterData/Repositories/Player/` |
| `Artist` | `ArtistRepositoryProtocol` / `ArtistRepository` | `Sources/PlaylisterData/Repositories/Artist/` |
<!-- codegen:repository-registry:end -->

### Authorization (no HTTP)

`AuthorizationRepository` does not use `NetworkClient` or DAOs: it forwards
`requestAuthorization(for: MusicProvider)` to the internal service of each provider, in `Remote/<Provider>/`.
Every provider service is `internal`, refines the public `AuthorizationServiceProtocol`
(e.g. `AppleMusicAuthorizationServiceProtocol`, backed by MusicKit) and is registered in
`AuthorizationRepository.init()`. A provider without a service throws `AuthorizationError.unsupportedProvider`.

### Login (no HTTP)

`LoginRepository` follows the same shape as `AuthorizationRepository`: it forwards
`login(with: MusicProvider)` to the internal service of each provider. Every provider service is
`internal`, refines the public `LoginServiceProtocol` (e.g. `AppleMusicLoginServiceProtocol`, which
checks the MusicKit authorisation, validates the session by fetching the storefront through `AppleMusicAPIClient`
and requires, through MusicKit's `MusicSubscription`, a subscription that can play the catalogue) and is registered
in `LoginRepository.init()`.
Failures are thrown as `LoginError`; a provider without a service throws `LoginError.unsupportedProvider`.

`SpotifyLoginService` (in `Remote/Spotify/`) asks `SpotifySession` for a token, reads the account with
`GET /v1/me` through `SpotifyAPIClient` and requires `product == "premium"` (`LoginError.subscriptionRequired`
otherwise): Spotify only lets Premium accounts control the playback. A closed or refused sign-in throws
`LoginError.notAuthorized`; a 401 forgets the tokens and signs in once more; any other failure throws
`LoginError.unavailable`. `SpotifyAuthorizationService` always answers `authorized` without showing anything:
Spotify has no system permission, the user consents on Spotify's page during the login.

### Spotify session (shared by the Spotify services)

`Core/Remote/Spotify/` holds what every Spotify service needs, like `Core/Remote/AppleMusic/` for Apple Music:

- `SpotifySession` (actor, `shared`) hands out a valid access token: the stored one, one renewed with the refresh
  token, or one from a new sign-in (Authorization Code with PKCE, no client secret) in `ASWebAuthenticationSession`
  (`SpotifyWebAuthenticator`). The tokens live in the **keychain** (`Core/Local/Spotify/SpotifySessionStorage.swift`,
  service `playlisterData.spotify`, account `session`), never in `UserDefaults`.
- `SpotifyAccountsClient` calls `POST https://accounts.spotify.com/api/token`, form encoded
  (`NetworkClient`'s `encoding: .form`).
- `SpotifyAPIClient` calls the Web API (`https://api.spotify.com/v1`) with the token. Add each new path to its
  `configuration.serviceNames`.
- `SpotifyAuthConfiguration` holds the scopes (asked for at once, so the other repositories need no new consent)
  and reads the Client ID from the app's Info.plist key `SpotifyClientID`. Without it the sign-in fails as
  `LoginError.unavailable`. The redirect URI `playlister://spotify-callback` must be listed in the app of the
  Spotify developer dashboard.
- `NetworkClient` throws `NetworkError.unacceptableStatusCode` for answers outside 200…299, so services can tell a
  rejected token (401) from other failures.

### LastPlaylist (local storage, no HTTP)

`LastPlaylistRepository` keeps the last playlist played with each `MusicProvider` on the device.
`fetch(_:)` takes a `LastPlaylistRequestProtocol` (the provider the user signed in with) and returns a
`LastPlaylistResponseProtocol` whose `lastPlaylist` (`LastPlaylistItemProtocol`: id, name, song count, `nil` when the
playlist was chosen without reading its songs, and up to four covers) is `nil` until one is saved. `saveLastPlaylist(_:for:)` stores a playlist for a provider and
replaces the previous one; each provider has its own entry. The internal `LastPlaylistStorageProtocol` (in `Local/`) is backed by
`LastPlaylistUserDefaultsStorage`, which writes the `Codable` `LastPlaylistItemDAO` as JSON under
`playlisterData.lastPlaylist.<provider>`. Do not change those keys: saved playlists would be lost.
Write failures are thrown as `LastPlaylistError.storageFailed`; unreadable data reads as no playlist.

### Settings (local storage, no HTTP)

`SettingsRepository` keeps the game settings of each `MusicProvider` on the device. `fetch(_:)` takes a
`SettingsRequestProtocol` (the provider the user signed in with) and returns a `SettingsResponseProtocol`
(a `GameSettingsProtocol`: playback mode, clip length and start, game mode, Bingo level and the Bingo categories
turned off per level), or the defaults (30-second clips from a random point, classic mode, every category on) until
something is saved for that provider. `saveSettings(_:for:)` replaces the settings of a provider; each provider has
its own entry. The internal `SettingsStorageProtocol` (in `Local/`) is backed by `SettingsUserDefaultsStorage`, which writes the
`Codable` `GameSettingsDAO` as JSON under `playlisterData.settings.<provider>`. Do not change those keys or the raw
values of the `Settings…` enums: saved settings would be lost. A missing field reads as its default, so adding a
setting keeps the rest. Write failures are thrown as `SettingsError.storageFailed`.

### Playlists (Apple Music API)

`PlaylistsRepository` follows the same shape as `LoginRepository`: each call is forwarded, as an internal DAO, to the
internal `PlaylistsServiceProtocol` of its provider, registered in `PlaylistsRepository.init()`. Every call returns
`PlaylistsItemProtocol`s with only what the service returns for the playlist itself (id, name, curator and artwork
URL) and **never reads the songs**. Each call is one request to the Apple Music API through `AppleMusicAPIClient` (and one more, cached by MusicKit,
for the storefront of catalogue paths), so the app can run them in parallel. Library and catalogue playlists share
`AppleMusicPlaylistAttributesDAO`.

| Call | Request | Returns |
|---|---|---|
| `fetchLibrary(_:)` | `LibraryPlaylistsRequestProtocol` (provider) | Up to `PlaylistsRepository.libraryLimit` (20) library playlists from `GET /v1/me/library/playlists` (Apple Music API), in the order the API returns them, with their web artwork when they have one. |
| `fetchRecommended(_:)` | `RecommendedPlaylistsRequestProtocol` (provider, `playlistIDs`) | Every catalogue playlist of the ids from **one** `GET /v1/catalog/{storefront}/playlists?ids=…`, in the order of the ids. Ids not in the catalogue (deleted or no longer shared) are left out without failing. |
| `search(_:)` | `PlaylistsSearchRequestProtocol` (provider, `term`, `offset`) | One page of `PlaylistsRepository.searchPageSize` (25) playlists from `GET /v1/catalog/{storefront}/search?types=playlists`, as a `PlaylistsSearchResponseProtocol` whose `hasMore` is `true` when the API announces a `next` page. An empty term returns no playlists. |

- The recommended ids live in the feature (`HitsterPlayListUseCase`). They are read by id, never searched: the public
  catalogue search barely returns playlists shared by users, such as the «Hitster» ones.
- The catalogue search seems to stop at about 100 results: past them the API announces no `next` page.
- Only `https` artwork URLs are kept.
- Without MusicKit access it throws `PlaylistsError.notAuthorized`, on any other failure
  `PlaylistsError.unavailable`, a cancelled call rethrows `CancellationError`, and a provider without a service throws
  `PlaylistsError.unsupportedProvider`.

### Song (Apple Music API)

`SongRepository` follows the same shape as `PlaylistsRepository`: `fetchRandomSongs(_:)` takes a
`SongRequestProtocol` (provider, `playlistID` and `count`) and forwards it, as the internal `SongRequestDAO`, to the
internal `SongServiceProtocol` of that provider, registered in `SongRepository.init()`. It returns a
`SongResponseProtocol` with up to `count` random `SongItemProtocol`s (id, title, artist and web artwork URL).

`fetchSongs(_:)` takes a `PlaylistSongsRequestProtocol` (provider, `playlistID` and `offset`) and returns one page of
`SongRepository.songsPageSize` (25) songs, in their order, as a `PlaylistSongsResponseProtocol`: its
`PlaylistSongItemProtocol`s (id, title, artist, web artwork URL or `nil`, duration when the API gives it, and
`catalogID`: the song's own id for a catalogue song, `playParams.catalogId` for a library one, `nil` when it has none;
`albumName`, `releaseYear` from `releaseDate`, and `largeArtworkURL` at `SongRepository.largeArtworkSide` (600) pixels), the
`total` songs of the playlist when the API sends `meta.total`, and `hasMore`, `true` when the API announces a `next`
page. Songs without artwork are kept. The selector's long-press sheet reads it through `FetchSongsFromPlaylistUseCase`.

- `AppleMusicSongService` (in `Remote/AppleMusic/`) reads the first page (100) of the playlist's songs through the
  Apple Music API in **one** request: `GET /v1/me/library/playlists/{id}/tracks` when the id starts with `p.`, else
  `GET /v1/catalog/{storefront}/playlists/{id}/tracks`. Each song already comes with its web artwork, so no song is
  looked up again. `RandomSongPicker` then picks `count` of those with artwork at random; with fewer songs with
  artwork it returns fewer.
- `fetchSongs(_:)` reads the same paths with `limit=25&offset=…`, one page per request.
- Only `https` artwork URLs are kept.
- Without MusicKit access it throws `SongError.notAuthorized`, an unknown playlist (API 404)
  `SongError.playlistNotFound`, any other failure `SongError.unavailable`, and a provider without a service `SongError.unsupportedProvider`.

### Player (MusicKit, no HTTP)

`PlayerRepository` follows the same shape as `SongRepository`, with no `NetworkClient`: every call names a
`MusicProvider` and is forwarded to the internal player of that provider, registered in `PlayerRepository.init()`.
`play(_:)` takes a `PlayerRequestProtocol` (provider, `songID` as the Song repository returned it, and `startTime`
in seconds), replaces whatever is playing with that song and returns a `PlayerResponseProtocol` (provider, `songID`
and the `duration` the player knows). `pause(provider:)`, `resume(provider:)`, `stop(provider:)`,
`playbackTime(provider:)` and `status(provider:)` (`PlaybackStatus`: `stopped`, `playing`, `paused`) drive the same
player.

- **Common contract:** `PlayerServiceProtocol` (internal) is what every provider implements: `play`, `pause`,
  `resume`, `stop`, `playbackTime` and `status`, all `async` so each player can hop to the actor its SDK needs.
- `AppleMusicPlayerService` (in `Remote/AppleMusic/`) plays with MusicKit's `ApplicationMusicPlayer.shared`, inside
  the app and without touching the Music app's queue. It looks the song up first: catalogue ids with
  `MusicCatalogResourceRequest<Song>`, library ids (`i.…`) with `MusicLibraryRequest<Song>`. Catalogue songs need
  `MusicSubscription.current.canPlayCatalogContent`.
- **Pass the `catalogID`** of `PlaylistSongItemProtocol` when it has one. A library id is only found when the song is
  in the device library, and a song added to a library playlist is not always added to the library (the iPhone's
  «Add Playlist Songs» setting), so `MusicLibraryRequest` misses it and the call throws `PlayerError.songNotFound`.
  The library id is only needed for songs without a catalogue equivalent, e.g. uploaded ones.
- **Spotify (pending):** add `Remote/Spotify/SpotifyPlayerService.swift` conforming to `PlayerServiceProtocol`
  (e.g. with the Spotify iOS SDK's App Remote, which needs the Spotify app and a Premium account) and register it
  under `.spotify` in `PlayerRepository.init()`. Until then Spotify calls throw `PlayerError.unsupportedProvider`.
- Without MusicKit access it throws `PlayerError.notAuthorized`, without a subscription
  `PlayerError.subscriptionRequired`, an unknown song `PlayerError.songNotFound`, a cancelled call rethrows
  `CancellationError`, and any other failure throws `PlayerError.unavailable`.

### Artist (MusicBrainz)

`ArtistRepository` tells whether the main artist of a song is a solo artist or a group, from the
[MusicBrainz web service](https://musicbrainz.org/doc/MusicBrainz_API) (`https://musicbrainz.org/ws/2`, no key).
`fetchKind(_:)` takes an `ArtistRequestProtocol` (`artistName` and the song's `isrc`, when it has one) and returns an
`ArtistResponseProtocol` with the `kind` (`ArtistKind`: `solo`, `group` or `unknown`) and the artist's name in
MusicBrainz.

- With an ISRC it calls `GET /isrc/{isrc}?inc=artist-credits` and reads the type of the first artist credited on the
  first recording (the main artist of «A feat. B»). Without one, when MusicBrainz does not know the ISRC, or when
  the recording's artist has no kind (`unknown`), it searches `GET /artist?query=artist:"…"&limit=1` and keeps the
  best match only with a score of `ArtistRepository.minimumSearchScore` (90) or more. When that search finds no
  kind either (or fails), the recording's `unknown` answer is kept.
- MusicBrainz types map as `Person` → `solo`; `Group`, `Orchestra`, `Choir` → `group`; anything else, or no match,
  → `unknown`, which is not an error.
- The internal `MusicBrainzClient` (in `Remote/MusicBrainz/`) calls through `NetworkClient` with the `User-Agent`
  MusicBrainz requires (`Playlister/<version> ( <contact> )`, set in `MusicBrainzClient.contact`), and
  `MusicBrainzThrottle` spaces every call 1.1 s apart: MusicBrainz allows one request per second.
- Answers are kept in memory for the life of the repository, by ISRC and by name (without case or accents).
- Only catalogue songs have an ISRC (`PlaylistSongItemProtocol.isrc`); songs of library playlists are searched by name.
- A failed search throws `ArtistError.unavailable`; a cancelled call rethrows `CancellationError`.
