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
| `Provider` | `ProviderRepositoryProtocol` / `ProviderRepository` | `Sources/Networking/Repositories/Provider/` |
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

### Provider (local storage, no HTTP)

`ProviderRepository` keeps the last playlist played with each `MusicProvider` on the device.
`fetch(_:)` takes a `ProviderRequestProtocol` (the provider the user signed in with) and returns a
`ProviderResponseProtocol` whose `lastPlaylist` (`ProviderPlaylistProtocol`: id, name, song count and up to
four covers) is `nil` until one is saved. `saveLastPlaylist(_:for:)` stores a playlist for a provider and
replaces the previous one; each provider has its own entry. The internal `ProviderStorageProtocol` is backed by
`ProviderUserDefaultsStorage`, which writes the `Codable` `ProviderPlaylistDAO` as JSON under
`networking.provider.lastPlaylist.<provider>`. Do not change those keys: saved playlists would be lost.
Write failures are thrown as `ProviderError.storageFailed`; unreadable data reads as no playlist.
