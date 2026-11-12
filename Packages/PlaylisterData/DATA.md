# PlaylisterData — configuration

The `PlaylisterData` package is the data layer of the app: it owns every repository, whether its data comes from a
remote API (Alamofire) or from the device (`UserDefaults`). Features never know where the data comes from.
Humans and coding agents must follow this file; the `playlister-new-repo` skill keeps the
**Repository registry** below up to date. Do not remove the `codegen` markers.

## Rules

- **Alamofire** is the HTTP layer, and only `Core/Remote/NetworkClient.swift` imports it.
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
| `Song` | `SongRepositoryProtocol` | `Sources/PlaylisterData/Repositories/Song` |
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
checks the MusicKit authorisation, validates the session by fetching the storefront and requires a
subscription that can play the catalogue) and is registered in `LoginRepository.init()`.
Failures are thrown as `LoginError`; a provider without a service throws `LoginError.unsupportedProvider`.

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

### Playlists (MusicKit, no HTTP)

`PlaylistsRepository` follows the same shape as `LoginRepository`: each call is forwarded, as an internal DAO, to the
internal `PlaylistsServiceProtocol` of its provider, registered in `PlaylistsRepository.init()`. Every call returns
`PlaylistsItemProtocol`s with only what the service returns for the playlist itself (id, name, curator and artwork
URL) and **never reads the songs**. Each call is one MusicKit request, so the app can run them in parallel.

| Call | Request | Returns |
|---|---|---|
| `fetchLibrary(_:)` | `LibraryPlaylistsRequestProtocol` (provider) | The `PlaylistsRepository.libraryLimit` (20) most recently played library playlists. |
| `fetchRecommended(_:)` | `RecommendedPlaylistsRequestProtocol` (provider, `playlistIDs`) | Every catalogue playlist of the ids in **one** `MusicCatalogResourceRequest`, in the order of the ids. Ids not in the catalogue (deleted or no longer shared) are left out without failing. |
| `search(_:)` | `PlaylistsSearchRequestProtocol` (provider, `term`, `offset`) | One page of `PlaylistsRepository.searchPageSize` (25) catalogue playlists, without top results, as a `PlaylistsSearchResponseProtocol` whose `hasMore` is `true` when the page was full. An empty term returns no playlists. |

- The recommended ids live in the feature (`HitsterPlayListUseCase`). They are read by id, never searched: the public
  catalogue search barely returns playlists shared by users, such as the «Hitster» ones.
- The catalogue search seems to stop at about 100 results: past them, pages come back empty and `hasMore` is `false`.
- Only `https` artwork URLs are kept (library artwork can use a MusicKit scheme `AsyncImage` cannot load).
- Without MusicKit access it throws `PlaylistsError.notAuthorized`, on any MusicKit failure
  `PlaylistsError.unavailable`, a cancelled call rethrows `CancellationError`, and a provider without a service throws
  `PlaylistsError.unsupportedProvider`.
