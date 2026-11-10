# Playlister

SwiftUI app for iOS (iPhone), iPadOS. It uses MVVM with a feature-based architecture and is split into Swift packages (`Networking` with Alamofire, and `PlaylisterUI`).

## Getting started

```bash
brew install xcodegen swiftlint
xcodegen generate
open Playlister.xcodeproj
```

The Xcode project is generated from `project.yml` and is not committed. Run `xcodegen generate` again after you pull changes that add files.

## Structure

```
Playlister/                 App target: App/, Core/, Features/, Resources/, FEATURES.md
Packages/Networking/         Repositories, DAOs and the Alamofire client (NETWORKING.md)
Packages/PlaylisterUI/       Tokens from Claude Design and UI components (DESIGN_SYSTEM.md)
scripts/codegen/             Generators used by the project skills
.claude/skills/              Project skills: new feature, new repository
```

See `AGENTS.md` for the conventions.
