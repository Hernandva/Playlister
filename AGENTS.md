# Playlister — instructions for coding agents

Playlister is a SwiftUI app (iOS (iPhone), iPadOS) written in Swift 6 language mode, with MVVM and a feature-based architecture. It is split into Swift packages.
Read the configuration file of the area you are working on before you change it, and follow it.

| Area | Path | Configuration |
|---|---|---|
| App scenes (features) | `Playlister/` | `Playlister/FEATURES.md`: feature anatomy, data flow, navigation and the app map |
| Repositories and APIs | `Packages/Networking/` | `Packages/Networking/NETWORKING.md`: repositories, protocols, DAOs, Alamofire |
| Design system and UI components | `Packages/PlaylisterUI/` | `Packages/PlaylisterUI/DESIGN_SYSTEM.md`: tokens, components, `.localized(_:)` |

## Skills

Project skills live in `.claude/skills/`, which Claude Code and GitHub Copilot both read. Any other agent can follow the same steps by reading the SKILL.md files.

- `playlister-new-feature`: new scene. Run `python3 scripts/codegen/new_feature.py --name X --parent Y [--repository Z]`.
- `playlister-new-repo`: new repository. Run `python3 scripts/codegen/new_repo.py --name X`.

Always use the generators to create features and repositories, so the structure and the registries stay consistent.

## Rules

- SwiftUI only. Feature views compose `PlaylisterUI` components and never hard-code colors, fonts or spacing.
- Features reach `Networking` only through a repository's public protocol, from the feature's use case.
- New dependencies are injected through the feature's `<Feature>Dependencies`: a `private let` plus a `resolve<Name>()` function.
- Every function of a `<Feature>Dependencies` that hands out a dependency is named `resolve<Name>()` (`resolveUseCase()`, `resolveViewModel()`, `resolveRepository()`). Never use the `make` prefix.
- `View`, `ViewModel` and `UseCase` receive only `init(dependencies: <Feature>Dependencies)` and resolve the rest inside it.
- SwiftLint runs on every build (`scripts/lint.sh`), and the build fails above **3 violations**.

## SwiftLint check for new code

Every time you add a variable, constant, property, function or method, check that it breaks no SwiftLint rule before you consider the change done. The 3-violation limit is a ceiling for the whole project, not a budget for new code: new code adds **zero** violations.

1. Write it with the rules in mind. The ones new declarations break most often:
   - `identifier_name`: lowerCamelCase, at least 3 characters (no `x`, `vm`, `tmp`), no leading underscores or snake_case.
   - `function_body_length`, `cyclomatic_complexity`, `function_parameter_count`: keep functions short and simple, and group many parameters into a type.
   - `line_length`: wrap long signatures and calls.
   - `force_cast`, `force_try`: use `as?` and `try` with real error handling.
   - `trailing_whitespace`, `vertical_whitespace`, `colon`, `comma`: standard Swift formatting.
2. Lint the files you touched right away, without waiting for a build:
   ```bash
   swiftlint lint --quiet path/to/File.swift   # one file
   scripts/lint.sh                             # whole project, same check as the build
   ```
3. If a violation points at your new declaration, fix the code (rename it, split the function, wrap the line). Do not silence it with `// swiftlint:disable` or by editing the SwiftLint configuration unless the user asks for it.
4. If SwiftLint is not installed, say so and review the code against the rules above by hand.

## Git flow

- `main` holds releases. `develop` is the integration branch.
- Every feature is built on `feature/Playlister-<Feature>`, created from `develop`.

## Build

```bash
xcodegen generate                      # creates Playlister.xcodeproj from project.yml (it is not committed)
open Playlister.xcodeproj
(cd Packages/Networking && swift test)  # package tests
```
