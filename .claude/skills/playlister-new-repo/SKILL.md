---
name: playlister-new-repo
description: Create a new repository in the Playlister Networking package (public repository protocol and class, public request/response protocols, internal DAOs, empty configuration) and register it in NETWORKING.md. Use it whenever someone wants to add an API, endpoint, service or data source to Playlister.
---

# New Playlister repository

Repositories live in `Packages/Networking/Sources/Networking/Repositories/<Name>/` and follow
`RequestProtocol -> RequestDAO -> ResponseDAO -> ResponseProtocol`. Read `Packages/Networking/NETWORKING.md`
before changing one. Never create the files by hand.

## 1. Collect the input

- **Name** (`--name`): PascalCase, without the `Repository` suffix (`Playlists`, `SpotifyAuth`).
  Check the repository registry in `NETWORKING.md` so it does not exist yet.

## 2. Run the generator

```bash
python3 scripts/codegen/new_repo.py --name <Name>
```

It creates the public `<Name>RepositoryProtocol` and `<Name>Repository`, the public `<Name>RequestProtocol`
and `<Name>ResponseProtocol`, the internal `<Name>RequestDAO` and `<Name>ResponseDAO`, and adds the
repository to the registry in `NETWORKING.md`.

## 3. Fill it in

- **Configuration:** set `baseURL` and `serviceNames` in `<Name>Repository.configuration`, only with values the
  user gives you. Leave them empty otherwise and say so: calls throw `NetworkError` until they are set.
- **Protocols:** add to the request and response protocols the fields the API needs, and mirror them in the DAOs
  (`Encodable` request, `Decodable` response that conforms to the response protocol).
- Keep the DAOs `internal`. Features only ever see the public protocols.
- Never put secrets (API keys, client secrets, tokens) in the source. Ask the user where they should come from.

## 4. Test, lint and commit

1. `(cd Packages/Networking && swift test)` on a Mac with Xcode.
2. Lint each file you touched: `swiftlint lint --quiet <file>`, then `scripts/lint.sh`. New code adds zero violations.
3. Commit on the current feature branch (`feature/Playlister-<Feature>` from `develop`), or create one from `develop`.

To use the repository from a screen, create or update the feature with
`python3 scripts/codegen/new_feature.py --name <Feature> --parent <Parent> --repository <Name>`.
