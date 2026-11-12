---
name: playlister-new-feature
description: Create a new feature (screen) in the Playlister app with its Coordinator, Dependencies, View, ViewModel, ViewData and UseCase, its feature/Playlister-<Feature> branch from develop, the route in the parent coordinator and the FEATURES.md update. Use it whenever someone wants to add a screen, scene, flow or feature to Playlister.
---

# New Playlister feature

Every screen of Playlister is a feature under `Playlister/Features/<Feature>/`. The generator creates the
structure, the branch and the registries, so features always come out the same. Never create the files by hand.

Read `Playlister/FEATURES.md` (anatomy, data flow, navigation) and `Packages/PlaylisterUI/DESIGN_SYSTEM.md`
(components) before writing the view.

## 1. Collect the inputs

| Input | Flag | Notes |
|---|---|---|
| Feature name | `--name` | PascalCase or words (`PlaylistSelector`, "playlist selector"). |
| Parent feature | `--parent` | The existing feature that opens it. See the registry in `FEATURES.md`. |
| Repository | `--repository` | Optional. A `Networking` repository the use case consumes. If it does not exist yet, create it first with the `playlister-new-repo` skill. |

## 2. Check the working tree

The generator branches from `develop` and refuses to run with uncommitted changes. Run `git status`. If there
are changes, ask the user whether to commit or stash them first; never discard them.

## 3. Run the generator

```bash
python3 scripts/codegen/new_feature.py --name <Feature> --parent <Parent> [--repository <Repo>]
```

It creates `feature/Playlister-<Feature>` from `develop`, the six files, the route
`<Parent>Coordinator.Route.<feature>`, the entries in the feature registry and app map of `FEATURES.md`,
and the `<feature>.title` key in `Localizable.xcstrings`. It regenerates the Xcode project when `xcodegen` is installed.

## 4. Build the screen

- **View:** compose only `PlaylisterUI` components (`DSScreen`, `DSText`, `DSButton`, `DSListGroup`, `DSListRow`,
  `DSToggle`, `DSSegmentedControl`, `DSPlaylistCard`, `DSVinyl`…). No hard-coded colors, fonts, spacing or radii.
  One `.primary` button per screen at most.
- **Text:** localise with `.localized("<feature>.<element>")` and add every new key to
  `Playlister/Resources/Localizable.xcstrings` (Xcode does not extract keys passed as values).
- **Initialisers:** `View`, `ViewModel` and `UseCase` take only `init(dependencies: <Feature>Dependencies)` and resolve
  the rest inside it with the container's `resolve…()` functions. A new dependency is a `private let` in
  `<Feature>Dependencies` plus a `resolve<Name>()` function (see "Initialisers: only the container" in `FEATURES.md`).
- **ViewModel:** `@MainActor @Observable`, state `idle / loading / loaded / failed`, and `private(set) var viewData`.
  Adds each use case result to its own field of `viewData`. Depends on the use case protocol.
- **UseCase:** calls the repository's public protocol and returns only the data of the response, mapped into a
  ViewData field type. It never builds or returns the whole ViewData (see "ViewData lives in the view model" in `FEATURES.md`).
- **Navigation:** open child features with `NavigationLink(value: <Feature>Coordinator.Route.<child>)`.

## 5. Lint and commit

1. Lint each file you touched: `swiftlint lint --quiet <file>`, then `scripts/lint.sh`. New code adds zero violations.
2. Build in Xcode (`xcodegen generate && open Playlister.xcodeproj`) if you can.
3. Commit on the feature branch. Open the pull request against `develop`, never `main`.
