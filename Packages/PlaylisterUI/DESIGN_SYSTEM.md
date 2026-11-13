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
| `DSListRow(_:subtitle:accessory:)` | 52 pt row. Accessory `.chevron`, `.checkmark` (`bubblegum`) or `.value(_:)` (`text-secondary`, e.g. «Conectado»). |
| `DSListButtonRow(_:style:action:)` | 44 pt action row in a `DSListGroup`: `.plain` (`bubblegum`) or `.destructive` («Cerrar sesión»). |
| `DSSlider(value:in:step:labels:)` | Slider row: title and value on top, slider between its minimum and maximum labels (`text-tertiary`), `magenta` track. `DSSlider.Labels` takes the texts localised. |
| `DSToggle(_:isOn:)` | Switch row; the 51 × 31 switch fills with the animated gradient when on (`DSSwitchToggleStyle`). |
| `DSSectionHeader(_:)` | Small-caps header above a `DSListGroup`. |
| `DSBottomSheet(title:message:primaryAction:secondaryAction:)` | Bottom sheet for `.sheet(item:)` / `.sheet(isPresented:)`: `title`, `message` in `text-secondary` and one or two stacked `DSButton`s (`DSBottomSheet.Action`, `.primary` by default, `.plain` for the secondary). Sizes itself to its content, aura background, `radius-sheet` corners, drag indicator, dark scheme. Texts are passed localised. |
| `DSStatusBadge(_:style:action:)` | Connection state capsule with a dot: `.spotify` (`spotify-green`) or `.appleMusic` (`tint-fill` + `tint-ink`). Top of Home with a session. With an `action` it is a button with a chevron and a 44 pt touch area. |
| `DSCard { … }` | Large block on `surface-1`, `hairline` border, `radius-panel`, `space-5` padding. |
| `DSIconButton(_:systemImage:style:diameter:action:)` | Round icon button. `.play` (96–132 pt, gradient + `magenta` pulse, only in Home), `.glass` (60 pt in game, 44 pt in nav bars), `.gradient` (Siguiente on the revealed view). The text is the accessibility label. `DSIconButtonStyle(_:diameter:)` gives the same look to a `NavigationLink`. |
| `DSChip(_:)` | Small non-interactive capsule with a short summary: `tint-ink` footnote semibold on `tint-fill`. Game mode at the top of the game («Clásico · 20 s», «Bingo · Principiante»). |
| `DSProgressBar(progress:elapsed:duration:width:smoothing:)` | Game playback progress: 4 pt track (`orchid` at 20 %) filled with the animated gradient, elapsed and total times under it in `text-secondary` with tabular digits. `progress` 0…1 (clamped), times passed formatted, `width` 230 pt by default (under the 250 pt vinyl). `smoothing`: when `progress` is read on a timer, pass its interval and the fill grows linearly between readings; going back and Reduce Motion jump. |
| `DSSegmentedControl(selection:segments:)` | 34 pt segments on `fill`; the selected one wears the gradient and slides. Titles are passed localised. |
| `DSPlaylistCard(_:subtitle:covers:size:)` | 2×2 mosaic of up to 4 covers (`radius-card`, `shadow-card`), name and song count. `DSCoverMosaic` and `DSCoverImage` are public too. |
| `DSPlaylistSection(_:state:items:cardSize:actions:tail:)` | Section of playlists that loads on its own: `sectionTitle` header (with an optional count), then a loading indicator, an error with a `.plain` retry, or a horizontal carousel of `DSPlaylistCard`s that bleeds into the `DSScreen` margins. Hidden while `DSSectionState.idle` and once `.loaded` with no items. Takes `DSPlaylistSectionItem`s (name, subtitle, covers), `DSPlaylistSectionTexts` (localised) and `DSPlaylistSectionActions` (select, retry, card appears). `tail` goes after the last card, e.g. a loader for the next page. With a `longPress` action (and `longPressAction` text for accessibility), holding a card runs it instead of `select`. |
| `DSSongsSheet(title:subtitle:covers:primaryAction:closeAction:content:)` | Large sheet with the songs of a playlist («Selector · pulsación larga»): 64 pt cover mosaic, `title`, summary in `text-secondary` and a 30 pt glass close button (44 pt touch area, `closeAction`'s title is its label), a `hairline`, the scrolling `content` and the `primaryAction` pinned at the bottom. Large detent, aura background, `radius-sheet`. |
| `DSSongRow(title:artist:duration:cover:)` | Song row: 48 pt cover (`radius-control`, placeholder without artwork), title, artist in `text-secondary`, duration in `text-tertiary`, `hairline` under the texts. |
| `DSVinyl(phase:category:level:levels:diameter:)` | Game vinyl. `.playing` (1.8 s per turn, equalizer bars, pass `levels` 0…1 to bind them to audio), `.paused` (the disc stops at its angle and turns on from it, the bars settle low) and `.revealed(cover:isPaused:)` (6 s per turn, cover pops in; with `isPaused`, e.g. when the song ends, the disc stops the same way). With a Bingo `category` it takes its color and shows the category name. |
| `DSBingoCategory` / `DSBingoLevel` | The five Bingo categories with their color, `ink` (`bg-night`) and localised `title(for:)` (keys `bingo.category.<color>.<beginner|expert>`). |
| `DSBingoCategoryRow(category:level:isOn:)` | Settings row: color square, name and switch; 45 % opacity when off. |
| `DSSongRevealCard(title:artist:year:details:trailingDetail:category:)` | Revealed song card on `surface-2`, or in the category color with `bg-night` text. `trailingDetail` goes right-aligned under the year (the duration). Insert it with `.transition(DSSongRevealCard.revealTransition)`. |

Styles shared by the components live in `Sources/PlaylisterUI/Styles/` (hand-written, not generated):

- `DSPrimaryGradient()`: animated primary gradient (8 s). Clip it to the shape that needs it.
- `.dsGlow()`: animated title glow (6 s).
- `.dsShadow(.glow | .card | .disc)`: shadow tokens (the generator does not read `shadow.tokens` yet).
- With Reduce Motion on, gradients and glow stay on their first frame.

New components go in `Sources/PlaylisterUI/Components/`, use only tokens, are `public` and include a `#Preview`. A component that shows a single text conforms to `DSLocalizableText`; components with several texts take them already localised.

## Localisation: `.localized(_:)`

Every component that shows text conforms to `DSLocalizableText` and gets a public `localized` extension. It receives a key, localises it and returns the component with the localised text:

```swift
DSText(style: .largeTitle).localized("profile.title")
DSButton { viewModel.save() }.localized("profile.save")
DSTextField(value: $email).localized("login.email.placeholder")
```

Keys are looked up in the app's `Localizable.xcstrings` (`Bundle.main`). Pass `table:` and `bundle:` to use another catalog. Because the key is passed as a value, Xcode does not extract it automatically, so add every new key to the String Catalog.
