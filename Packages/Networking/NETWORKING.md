# Networking — configuration

The `Networking` package owns everything related to repositories and remote APIs.
Humans and coding agents must follow this file; the `playlister-new-repo` skill keeps the
**Repository registry** below up to date. Do not remove the `codegen` markers.

## Rules

- **Alamofire** is the HTTP layer, and only `Core/NetworkClient.swift` imports it.
- Each repository lives in its own folder: `Sources/Networking/Repositories/<Name>/`.
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
└── DAO/
    ├── NewRequestDAO.swift      # internal Encodable built from NewRequestProtocol
    └── NewResponseDAO.swift     # internal Decodable that conforms to NewResponseProtocol
```

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
| `Authorization` | `AuthorizationServiceProtocol` / `AuthorizationRepository` | `Sources/Networking/Repositories/Authorization/` |
| `Login` | `LoginServiceProtocol` / `LoginRepository` | `Sources/Networking/Repositories/Login/` |
| `LastPlaylist` | `LastPlaylistRepositoryProtocol` / `LastPlaylistRepository` | `Sources/Networking/Repositories/LastPlaylist/` |
| `Settings` | `SettingsRepositoryProtocol` / `SettingsRepository` | `Sources/Networking/Repositories/Settings/` |
<!-- codegen:repository-registry:end -->

### Authorization (no HTTP)

`AuthorizationRepository` does not use `NetworkClient` or DAOs: it forwards
`requestAuthorization(for: MusicProvider)` to the internal service of each provider.
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
`LastPlaylistResponseProtocol` whose `lastPlaylist` (`LastPlaylistItemProtocol`: id, name, song count and up to
four covers) is `nil` until one is saved. `saveLastPlaylist(_:for:)` stores a playlist for a provider and
replaces the previous one; each provider has its own entry. The internal `LastPlaylistStorageProtocol` is backed by
`LastPlaylistUserDefaultsStorage`, which writes the `Codable` `LastPlaylistItemDAO` as JSON under
`networking.lastPlaylist.<provider>`. Do not change those keys: saved playlists would be lost.
Write failures are thrown as `LastPlaylistError.storageFailed`; unreadable data reads as no playlist.

### Settings (local storage, no HTTP)

`SettingsRepository` keeps the game settings on the device; they are the same for every `MusicProvider`, so
`SettingsRequestProtocol` has no fields. `fetch(_:)` returns a `SettingsResponseProtocol` (a `GameSettingsProtocol`:
playback mode, clip length and start, game mode, Bingo level and the Bingo categories turned off per level), or the
defaults (20-second clips from a random point, classic mode, every category on) until something is saved.
`saveSettings(_:)` replaces them. The internal `SettingsStorageProtocol` is backed by `SettingsUserDefaultsStorage`,
which writes the `Codable` `GameSettingsDAO` as JSON under `networking.settings`. Do not change that key or the raw
values of the `Settings…` enums: saved settings would be lost. A missing field reads as its default, so adding a
setting keeps the rest. Write failures are thrown as `SettingsError.storageFailed`.
