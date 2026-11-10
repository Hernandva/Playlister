# PlaylisterUI — configuration

The `PlaylisterUI` package holds the design system of `Playlister`, generated from a Claude Design design system, and the components built on it.
Feature views only add these components. They never set colors, fonts, spacing or corner radii themselves.

## Source of truth

- `tokens.json` (this folder) is the tokens export of the Claude Design design system. In Claude Design it is `project/tokens.json`.
- `Sources/PlaylisterUI/Tokens/*.swift` and `Sources/PlaylisterUI/Resources/Colors.xcassets` are **generated** from it. Do not edit them by hand.
- To update the design system, replace `tokens.json` and run:

```
python3 scripts/codegen/design_tokens.py Packages/PlaylisterUI/tokens.json Packages/PlaylisterUI
```

## Tokens

| Swift type | Contents |
|---|---|
| `DSPalette` | Every color token, with light and dark values, from the asset catalog. |
| `DSColor` | Semantic roles used by the components: `background`, `surface`, `textPrimary`, `textSecondary`, `accent`, `onAccent`, `fillSecondary`, `destructive`, `onDestructive`, `separator`. |
| `DSTypeScale` / `DSFont` | Every type style / semantic fonts: `largeTitle`, `title`, `headline`, `body`, `bodyStrong`, `footnote`, `caption`. |
| `DSSpacing` | Every spacing token, plus `xSmall`, `small`, `medium`, `large`, `xLarge` and `tapMin`. |
| `DSRadius` | Every radius token, plus `small`, `control` and `card`. |

Custom fonts named in the tokens must be added to the app bundle (`.ttf`/`.otf`) and registered under `UIAppFonts` (iOS) or `ATSApplicationFontsPath` (macOS). Until then, SwiftUI falls back to the system font.

## Components

They follow the component guides of the Playlister design system (Claude Design). The app is always dark.

| Component | Use |
|---|---|
| `DSScreen { … }` | Root container of every screen: scroll view, aura background (`bg-night` + violet/magenta radials), `space-4` margins, `space-6` between blocks, `bubblegum` tint, dark scheme. |
| `DSAuraBackground()` | The same background, for sheets and full-screen views. |
| `DSText(_:style:color:)` | Any text. Styles: `.hero`, `.largeTitle` (both with the animated glow), `.title`, `.sectionTitle`, `.headline`, `.body`, `.bodyStrong`, `.subheadline`, `.footnote`, `.caption`. |
| `DSButton(_:style:action:)` | Actions. `.primary` (52 pt capsule, animated gradient, `shadow-glow`, one per screen), `.secondary` (`tint-fill` + `tint-ink`), `.plain` (`bubblegum`), `.destructive`, `.spotify`, `.appleMusic`. `DSButtonStyle` for custom labels. |
| `DSTextField(_:value:systemImage:)` | Text input on `fill`. `systemImage: "magnifyingglass"` for search. |
| `DSListGroup { … }` | Inset grouped list: `surface-2`, `radius-list`, `hairline` between rows. |
| `DSListRow(_:subtitle:accessory:)` | 52 pt row. Accessory `.chevron` or `.checkmark` (`bubblegum`). |
| `DSToggle(_:isOn:)` | Switch row; the 51 × 31 switch fills with the animated gradient when on (`DSSwitchToggleStyle`). |
| `DSSectionHeader(_:)` | Small-caps header above a `DSListGroup`. |
| `DSCard { … }` | Large block on `surface-1`, `hairline` border, `radius-panel`, `space-5` padding. |

Styles shared by the components live in `Sources/PlaylisterUI/Styles/` (hand-written, not generated):

- `DSPrimaryGradient()`: animated primary gradient (8 s). Clip it to the shape that needs it.
- `.dsGlow()`: animated title glow (6 s).
- `.dsShadow(.glow | .card | .disc)`: shadow tokens (the generator does not read `shadow.tokens` yet).
- With Reduce Motion on, gradients and glow stay on their first frame.

New components go in `Sources/PlaylisterUI/Components/`, use only tokens, are `public` and include a `#Preview`. A component that shows text conforms to `DSLocalizableText`.

## Localisation: `.localized(_:)`

Every component that shows text conforms to `DSLocalizableText` and gets a public `localized` extension. It receives a key, localises it and returns the component with the localised text:

```swift
DSText(style: .largeTitle).localized("profile.title")
DSButton { viewModel.save() }.localized("profile.save")
DSTextField(value: $email).localized("login.email.placeholder")
```

Keys are looked up in the app's `Localizable.xcstrings` (`Bundle.main`). Pass `table:` and `bundle:` to use another catalog. Because the key is passed as a value, Xcode does not extract it automatically, so add every new key to the String Catalog.
