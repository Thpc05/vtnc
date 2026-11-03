# The shell's style: M3 Expressive on the shell's colors

Every Dwidget is drawn in one style, **`expressive`**, from the user's M3 Expressive references:
- visible containers: `Kit.expressive` tokens (`container` / `off` / `high` = M3 `surfaceContainer` / `High` /
  `Highest`, as caelestia, since 2026-10-08);
- on = `primary` with `overPrimary` content (filled Material Symbols icons);
- rounded squares (tiles 16, pressed 12), M3 sliders (flat or wavy), a play square whose corners tighten
  while playing;
- the M3 expressive motion curves from the style kit;
- "no card" variants of each style put the content straight on the dashboard.

**History:** Sumi / Poster, the M3 recipes and caelestia's quick toggles were tried and dropped (2026-09-27).
The `vtnc` style (modelled on One UI 9's control center: dark glass, circles, pills) was the main one until
2026-09-29, when the user dropped it for expressive only. The style selectors stay, even with one style.

## Caelestia-inspired pass (2026-10-08, by stage: see the plan `cleanup-segue-sendo-importante-cheeky-wave.md`)

Inspired by caelestia / midnight-shell, **never dependent on it**: no `Caelestia.*` imports, no M3Shapes, nothing
read from its config or state. Stage 0 (foundation) is done:
- **Scales** (`Store.theme.scale.{rounding, spacing, padding, font, anim}`, Settings → Appearance → Scale, 1 =
  factory): `Kit` rounding / spacing / padding / fonts / durations and `Tokens` (roundness 16, spacing, font
  base 14, island duration 450 ms) are multiplied by them. anim 0 = no animations. The old absolute keys
  (`roundness`, `fontSize`, `anim.duration`) are migrated by `StateMerge.migrateTheme`.
- **Fonts:** Google Sans Flex with the `ROND 25` axis (`Kit.axes`); `Kit.font.headline/title/body/label/mono/icon`;
  `Kit.clockFamily` = Rubik (the clock iwidget's default); factory mono = CaskaydiaCove NF.
- **Transparency** (`Store.theme.transparency.{enabled, base, layers}`, Appearance → Transparency; off by
  default): `Colors.layer(c, n)`, caelestia's, ported: layer 0 (the page) takes `base` alpha, layers 1+ take
  `layers` alpha, lifted by a luminance offset that grows with the wallpaper's luminance (`luminance` in
  matugen.json, computed by `Wallpapers` with ImageMagick: the mean of sqrt(0.299r² + 0.587g² + 0.114b²)).
  Light mode lowers `base` by 0.1. `services/Hypr.qml` sets the blur layer rules at runtime (`hyprctl eval`) for
  `vtnc` (the frame, island and apps): blur only while transparent, `ignore_alpha` = base − 0.03; re-applied on
  `configreloaded`. `~/.config/hypr/vtnc/rules.lua` has no static blur.

**Stage 1 (the component library, 2026-10-08)**: caelestia's controls ported into `kit/`, pure QML on Kit
tokens and `Colors` (no plugin):
- buttons: `ButtonBase` (Filled / Tonal / Text, radius morph large → medium checked → small pressed, `isRound`,
  `shapeMorph`), `IconButton` (rebuilt on it; `size` px and `active` kept), `TextButton`, `IconTextButton`;
- `Switch` (check / cross thumb), `RadioButton`; `M3Slider` stays the slider (it already is caelestia's
  StyledSlider, plus wavy / round thumb; caelestia's FilledSlider was ported and then dropped: the user prefers the M3 one);
- `TextFieldBase` (blinking primary cursor), `TextField` (Outlined / Filled, floating label, validation),
  `SearchBar`; `Menu` + `MenuItem`; `ScrollBar`; `Elevation` (dp 0–5); `AnchorAnim`;
- **`M3Shape`, our own M3 shape library**: polar outlines (circle, square, pill, cookie4/6/7/9/12, sunny,
  softBurst, clover4/8) that morph by interpolating radii (`CookieShape` is superseded, unused).
- Colors gained `inverseSurface`, `overInverseSurface`, `inversePrimary`.
- Legacy `components/` keep their APIs: `Toggle` wraps `K.Switch`; `IconButton` is a Text icon button (round
  state layer, tightening while pressed, filled icon, no hover tint); `Card` uses Kit radii. Settings
  `SmallButton` is a `K.TextButton` (tonal / accent filled / danger), `Segmented` moves on Kit motion with state layers.
- **Review:** Settings → About → Components (`apps/settings/pages/ComponentGallery.qml`) shows every control
  in every state.

**Stage 2 (the frame, 2026-10-08)**: caelestia's screen frame replaces the screen corners (`appearance.json`
`frame` {enabled, thickness 10, rounding 25}; `corners` is migrated). **One surface:** `IslandWindow`'s
`surface` layer draws the frame and the island's body as one liquid shape (since stage 8: `K.BlobSurface`, our
SDF shader `kit/shaders/blob.frag`: the frame an inverted rounded rect, the body a `K.Blob` with the island's slide /
hop / width-scale transforms, merged with a circular smooth-min; the notch's flares are that merge radius, the
floating island merges into the edge as it nears it) under ONE MultiEffect shadow (blurMax 15, shadow at 0.7) and one opacity (the
transparency base); the fills inside are opaque. The island hangs from the frame's inner edge (`Island.frameTop`
in its `topGap`); its content stays outside any layer. The frame collapses (thickness and radius → 0,
DefaultSpatial) while a window is fullscreen. `frame/FrameExclusions.qml`: an exclusive zone of the thickness
on each edge (namespace `vtnc:frame`), under the island's own reservation.

**Stage 3 (island transients, 2026-10-08)**: the OSD keeps vtnc's own layout (the user's choice: a symmetric
bar as long as the level, the icon left, the percent right, a circle at 0), its bar a plain pill (no handle)
in the M3Slider's active-track color and thickness (8 px), growing from the centre. K.M3Slider stays THE
slider of the shell (user: "lindo"). caelestia's FilledSlider OSD was tried and removed.
The notification card follows caelestia's:
round app icon / image (low = surfaceContainerHighest, normal = secondaryContainer, critical = error), the
summary in onSurface, app name / time / body in onSurfaceVariant, kit font at the compact px sizes, critical on
a secondaryContainer card, round dismiss and action buttons (`K.IconButton` / `K.TextButton`, isRound +
shapeMorph, surfaceContainerHighest at layer 2; critical: secondary), inactive dots in outlineVariant.
caelestia's ring around the icon is the notification's progress hint, which vtnc's notifications don't carry
yet (not ported).

**Stage 4 (apps, 2026-10-08)**: the user kept vtnc's layouts everywhere, with caelestia's look:
- launcher: `K.SearchBar` (keys kept), rows with the name (onSurface, medium) and description (outline), the
  current one on secondaryContainer (rounding large), a `K.StateLayer` ripple (hover tint only off the current row);
- session / tools (`components/ActionRow`): caelestia's session colors on vtnc's row: bare icons at rest (no
  card, user), the current one (it follows the hover) a tonal rounded square (secondaryContainer; errorContainer for "error" actions), small
  radius while pressed, a state layer ripple;
- wallpaper: `K.SearchBar`, the scheme pill tonal (secondaryContainer) with a state layer (click / right click /
  wheel kept), the light toggle a `K.IconButton` toggle (Filled: container off, primary on), thumbnails on container.

**Stage 5 (settings, 2026-10-08)**: vtnc's layouts kept (user): the tree sidebar and the two-column sections,
with caelestia's look: the sidebar on container (rounding largeIncreased), rows with `K.StateLayer` ripples, the
selection a secondaryContainer pill moving on Kit motion, the current page's icon in a round primary chip;
sections a container card (rounding largeIncreased) with a small primary label title in the kit font; the
hand-drawn pages' radii / alpha tricks on Kit tokens (`K.Kit.rounding.*`, `Qt.alpha`). No settings search yet
(user: later). Icons: hibernate = `ac_unit`, record region = `filter_center_focus`, record screen = `videocam`.
Then (user): Appearance first in the sidebar; Island's icon `Icons.island` = `landscape` (user's pick until Material has an island;
`components/Icon` also takes an "@degrees" suffix to turn a glyph); sub-pages Island → Layout, Dashboard → Layout (2026-10-09; were Nwidgets / Dwidgets), About → Examples; Appearance → General's scheme is
the same Segmented as Colors'; the frame and the rounded corners are independent (`frame.enabled` + thickness,
`frame.roundCorners` + rounding; the old "thickness 0" = corners only is migrated to frame off).

**Stage 6 (Dwidgets, one at a time, 2026-10-08)**: the user picks each Dwidget's layout (vtnc's or caelestia's);
the new look replaces the `expressive` style (no extra catalog variant).
- From the calendar on (user): **forget the old vtnc Dwidget styles**; each Dwidget is redone from scratch after
  research on Google's M3 Expressive apps.
- calendar (the user's reference picture; Google's own apps were judged too plain, "pouco expressive"): compact,
  big numbers, two tones on a primaryContainer card (rounding extraLarge): strong = onPrimaryContainer (onSurface
  without the card), weak = primary at 55 %; "Jul 2026" centred (month bold primary, year weak); one-letter
  weekdays (today's strong); only this month's days, gone by strong and to come weak; today a primary rounded
  square (onPrimary; tertiary was tried). No arrows: wheel (slide + fade), title / middle click → today. Rejected on the way: caelestia's
  layout, a Sunny today, tertiary weekends, the old vtnc band layout, Google's block grid, an outlined today, the
  Google Calendar month picker (too simple).
- media: redone from scratch, four looks, all kept as styles (user): cover (A: the art
  fills the card, a veil, white bold title, a big primary play square → circle, wavy progress at the bottom), disc
  (B: a turning round record with the play as its spindle, a wavy ring progress (`WavyRing`, seeks on the ring),
  tonal prev / next at its corners), type (C: the calendar's two tones on primaryContainer, a huge bold title, a
  thick two-tone bar, a wide play pill), android (D: Android 16's QS player, the blurred art behind a 50 % scrim, a
  small art + titles on top, wavy progress, white play pill; blur 0.35, softened by the user). Disc and Type also
  without the card (discNoCard / typeNoCard). The play always morphs a rounded square → a circle
  (pill) while playing.
- quick configs + the Wi-Fi / Bluetooth / Mixer toggles: shapes (A: M3E shape buttons, rounded square off →
  primary circle on, tighter pressed; the hover follows the shape) and tones (B: two tones on primaryContainer),
  both also without the card. Tried and removed (user): Android 16 QS tiles, an M3E connected button group / split
  button. The old expressive tiles and their migrations are gone.
- sliders (K.M3Slider everywhere, user): inset (A: compact thick tracks ≤ 44 px (36 px alone), the icon inside the track's
  start, Android 16's volume sliders, 6 px around the handle — `K.M3Slider.handleGap`), tones (B: two tones, no percent, icon +
  name, the filled part primary / rest faint), wavy (D: thin wavy tracks while music plays,
  a 32 px tonal round icon button with the icon kept at its size, the number beside).
- Every Dwidget with a card / no-card pair defaults to **no card** (the no-card style is the tree's parent).
- The cards' colour is one setting for every Dwidget (user, 2026-10-08): Settings → Dashboard → Cards, neutral
  (surfaceContainer, default) / container (primaryContainer) / tinted / primary, drawn through the `K.Kit.card`
  palette (`K.Kit.bare` without a card; dwidgets/README.md). The per-style card colours below (primaryContainer
  for the two-tone styles) are replaced by it.
- panels (Wi-Fi, Bluetooth, Mixer, Night light, Power): they follow the Dwidget that opened them (user). Shapes →
  an M3E segmented list (`PanelRow`: blocks with 4 px inner corners and 16 px ends, the current primaryContainer with
  a primary icon circle, the others a container circle); Tones → two tones (no blocks, current strong + bold, the rest
  weak, an open row on a faint fill). Header without a block, a 16 px bold title; buttons primary / tonal / faint. The Mixer panel too: Shapes → the output / input sections two joined blocks and each app a block of a segmented list; Tones → bare. A big-number look (C) was offered and not picked.
- Stage 7, iwidgets (one at a time, the user picks; old styles that conflict are removed):
  - workspaces (2026-10-08): shapes (caelestia's: 1…N, a small circle each (empty outlineVariant, occupied primary; user: no square),
    the active one a random K.M3Shape at 0.8 in primary) / tones (Rubik numbers, occupied strong, empty primary at
    45 %, a sliding primary rounded square) / pills (vtnc's merged occupied pills + stretchy highlight, dots) /
    icons (app icon on a container rounded square, the active a primary circle, empty a dot). Occupied, unfocused
    ones are primary in every style (user). Old dots / numbers
    removed (unknown styles fall back to the catalog default, shapes).
  - clock + date (2026-10-08): split into two Iwidgets (user), each styled on its own (`island.clock` / `island.date`,
    `iwidgets/clock/TextPill.qml`): format, font (clock Rubik / date Google Sans Flex by default), weight, size, letter
    spacing, roundness (the ROND axis), colour role (default / muted / primary / secondary / tertiary) and a background
    (none / container / tonal / primary) with its own rounding (pill by default). The old `timeDate` style is gone;
    `island.clock.dateFormat` moves to `island.date.format` (StateMerge).
  - status (2026-10-08): volume pill (icon + number on secondaryContainer, errorContainer muted) / iconSlider (icon,
    thin K.M3Slider wavy while music plays, number) / slider (alone); battery upright (a classic battery standing up, cap on top, filled from the bottom, the number beside; user, after a pill) / text / ring (K.WavyRing, moved to
    the kit, wavy while charging); notifications bell / badge (a primary count at the corner) / count (a primary
    pill). Old icon / iconBar, arc / arcPercent and default removed. OSD: `osd.skipWithVolumeWidget` (Appearance → Popups,
    on by default): no volume OSD while the volume Iwidget shows in the island's current mode (compact / expanded).
  - battery redone (2026-10-11, R1a): **Shapes / Two tones / Tone** (the Quick configs' QMark with Android 16's lying
    battery symbol, on = plugged in, error when low) and **Ring** (the arc in the tone; its rest an exact PathAngleArc,
    the polyline left a stray dot on the GPU) and **Arc** (the ring with only its charged arc, user), all with Card
    variants. Options `island.battery.color` (the tone's
    role) and per mode `show` (both / icon / text). Upright / text (briefly merged as Default, then removed — user)
    migrate to Shapes.
  - volume OSD as its widget (2026-10-11, R1a): `osd.volumeWidget` (Appearance → Popups): the volume Iwidget shows for a
    moment instead of the slider (Island.volumeFlash, revealing an auto-hidden island like the transient); it needs a
    volume Iwidget in the layout (hidden in both modes is fine), else the slider shows (a warning in the settings).
    Its look: the volume's one style (below) with that mode's options.
  - volume, one style (2026-10-11, user): **Slider** (+ Card); the pill went, and Icon + slider / Slider became
    options per mode, `island.volume.<mode>.icon / percent`, plus `island.volume.wavy` (the wave while music plays).
    Old styles migrate (the old Slider alone = icon and percent off in that mode).
  - island motion and transients (2026-10-11, R1 — stage 8's leftovers): the content moves on the body's curve (WidgetSlot,
    DefaultView, the workspaces' counts, the settings preview, the OSD bar: K.Anim DefaultSpatial; fades K.Anim effects;
    ContentAnim no longer used on the island). **Jelly** (removed 2026-10-27, user; was `kit/Jelly.qml`): a damped spring fed by the body's width /
    height speed; it stretches the body (IslandWindow's blob `deform`) and the content (a Scale in Island) and wobbles
    back; the notch only stretches across. **Notification card** redone (`island/transient/NotificationCard.qml`):
    Shapes / Two tones / Tone (`island.notifications.style`, colour `island.notifications.color`), the lead a picture
    circle or the app icon (on a random M3 shape in Shapes, user), critical = the error tone, actions per look; the dismiss
    **fly-off** (slides right and fades, then discards). Kept raw on purpose: loops (disc spin, recording pulse, the
    bell's shake), the pagination worm's lead / trail timing and the visualizer's per-frame smoothing.
  - Island → **Anchors** (2026-10-11, user; under Layout): `island.anchors` = `gap` (between a section's widgets),
    `between` (between the sections), `left / center / right.card` (the island card behind the whole section: its
    widgets get the card's palette and their own Card variants merge into it). "Anchor center" moved there from
    General. IdleView's Section is now an Item (card + row; the card's padding shrinks with the row).
  - tray (2026-10-11, user): the **Compact** style became an option per mode, `island.tray.<mode>.fold` = off / left
    (<: the chevron after the icons, they open to its left) / right (>: before them), for Icons and Tint (with or
    without card); old compact / chevron migrate to Icons (+ Card) folded "right" (where the chevron was). Fixed: the chevron's
    width came from its inherited `visible`, so in the island's slot (invisible at width 0) it never showed.
  - tray / media / recording (2026-10-08, all options kept — user): tray icons (round state-layer hover) / chevron
    (caelestia's: unfolds inline) / pill (container) / mono (MultiEffect colourised, primary on hover); media title +
    controls (the blurred CompactPlayer card) / disc (a turning round art + title) / tones (a primary play button that
    rounds while playing, the title primary bold, the artist weak) / wavy (the title over a thin K.M3Slider, wavy while
    playing); recording dot / pill (errorContainer) / stop (a round error button). Old `default` ids removed.
- Stage 7b (2026-10-09): Nwidgets are now **Iwidgets** (`iwidgets/`); Settings → Island → Layout and Dashboard → Layout.
  - Card variants (user: only where they make sense): `<base>Card` styles in `iwidgets/catalog.js` (no card = the
    parent and default); `iwidgets/IwidgetFrame.qml` (WidgetSlot + the settings preview) draws the island card and
    hands the widget its `pal` (`K.Kit.islandCard`, colour in Island → General → Card colour, or `K.Kit.bare`);
    `kit/CardPalette.qml` is the shared palette (Kit.card / Kit.islandCard). Settings: a Card switch beside the style.
    Workspaces (all), clock / date (the Background option kept too), volume iconSlider / slider, media tones / wavy.
  - Media: Card / Card + controls redone on the island card (no blurred art over it): a small art with the title and
    artist, or today's controls row; wavy = tones with a short wave beside the text.
  - Workspaces: pills → pagination (dots, the active a long accent pill on a spring); a count per island mode
    (`island.workspaces.compactCount / expandedCount`, 0 = dynamic); shapes' colour switches instantly.
  - Tray: chevron → compact (folds back when the island collapses); mono → tint (below).
  - New Quick configs Iwidget (`iwidgets/quick`): the dashboard's Qwidget models, toggle only, shapes / tones (+ Card),
    items in `island.quick.items` (Island → Layout; the Mixer left out).
  - Media: styles Default (was "Card") / Controls (was "Card + controls") / Disc / Two tones, every one with a Card
    variant (the frame draws the island card; CompactPlayer no longer has its own); options per island mode
    (`island.media.compact / expanded`: art / title / artist / wave on every style, width), two columns in settings.
  - Visualizer Iwidget (`iwidgets/visualizer`, from services/Cava.qml): bars / dots (4 px, on/off) / shapes (one
    K.M3Shape morphing with the energy, breathing and turning) (+ Card; wave / blob dropped, user); collapses while
    nothing plays (after `hideDelay` s), cava held only while it shows (3 s grace); one cava per bar count
    (`Cava.acquire(n)` / `valuesFor(n)`; both modes' counts held while visible) so few bars aren't averaged into
    slow motion; even bar heights + per-frame smoothing (no tremble); source music / random; bars max / min height (min 0 = silent bars vanish); `island.visualizer` colour + per mode bars / width.
  - Workspaces dynamic = only the occupied ones and the active one (a number = 1…N).
  - Workspaces app icons became an option of every style (`island.workspaces.appIcons`; the "icons" style removed,
    migrating to pagination + app icons): an occupied one is its icon, the active one holds it on its own mark
    (shapes: the shape, larger; tones: the square; pagination: an accent circle, springing in).
  - Active window Iwidget (`iwidgets/window`, 2026-10-11): the focused window's title ("Desktop" without one), display
    only (no click / hover); the title cross-fades on change. Styles App icon / Two tones ("Both" split at the last dash:
    "Page" accent bold + "App" weak; First / Second one part) / Tone (was Category; caelestia's bar: symbol + title in
    the accent) / Shapes (category symbol on a random accent M3 shape per app), each + Card; `island.window` per mode: showIcon, text (first / second
    / both / none: the title split at its last dash; old shortTitle → first), maxWidth, weight. No icon + no text → collapses. Title changes settle: one after a quiet spell shows at once, close ones wait
    300 ms of stillness (1.2 s max) — apps retitling as they open (kitty) flickered. Only a window on the focused workspace counts (an empty workspace = Desktop).
    It fills its slot (`fillsSlot`): the title is revealed / covered with the slot's animated width. Settings Segmented: the choice is primary.
  - Later the same day (user): workspaces icons = the app icon alone, empty ones pagination's dots; pagination
    taller active pill, both pills on one curve (the row never changes width); tray mono → **tint** (caelestia's
    recolour: MultiEffect colourised, brightness 1 − the icon's dominant lightness, measured by a tiny Canvas in
    `iwidgets/tray/TintedIcon.qml`; `island.tray.tintColor`, primary by default; renamed styles migrate); media: Island → Layout → Media switches art / title / artist / wave for Card, Disc
    and Two tones (`iwidgets/media/InfoRow.qml`), the Wavy style removed.

## The whole shell (2026-09-29, M3 pass)

- **Backgrounds:** the page is `Colors.background`: M3 `surface` by default (since 2026-10-08; it was `oled`);
  pure black / white (`oled`) or anything else is a mapping in Appearance → Colors.
- **One surface ladder** (`Kit.expressive`, each through `Colors.layer`): page (layer 0) → container
  (`surfaceContainer`: cards, panes) → off (`surfaceContainerHigh`: controls, fields) → high
  (`surfaceContainerHighest`: a control on a control, hover) → tonal (`secondaryContainer`) / on (`primary`).
  `components/StyledRect` variants and `Card` map onto it
  (no compat); `Toggle` is the M3 switch; `IconButton` has an M3 state layer.
- **Icons:** `theme/Icons.qml` holds Material Symbols Rounded names (the old property names kept), so every
  `Icon`/`IconButton` in the shell draws the M3 set with its axes. Brand icons stay Nerd Font rich text.
- **Font:** Google Sans Flex (`Tokens.defaultFamily`), unless the user picks one in Appearance.

## Where it lives in code

- **The style kit** (`kit/`, `import qs.kit as K`, whose names clash with `qs.components`):
  - `Kit` holds the tokens: rounding, spacing, padding, fonts (Google Sans Flex when installed), the M3
    motion curves and durations, and `Kit.expressive` (the containers, the radius, the slider sizes).
  - `Anim` and `CAnim` animate on those tokens.
  - `StyledRect` and `StyledText` are the base shapes and text.
  - `MaterialIcon` is a Material Symbols Rounded icon (the M3 set) with its axes set as M3 asks: FILL 0 → 1
    for on, GRAD -25 on dark, wght 400, and opsz = the drawn size (20…48). `size` in px. `IconButton` is the
    clickable one.
  - **Icons (test, 2026-09-29):** the whole dashboard (Dwidgets and their panels) uses Material Symbols; the rest
    of the shell still uses Phosphor (`components/Icon`). If the test goes well, the rest follows.
  - `StateLayer` draws hover and the ripple.
  - `M3Slider` (flat or wavy, bar or round thumb, a value bubble) on `SliderInput`; `CookieShape`.
  - Most of these were ported from caelestia-dim (`~/Codes/GitHub/midnight-shell`).
- **Rule:** a Dwidget's **id is its purpose**, and its **style is what makes it**. A style offers only the sizes
  it fits. See `dwidgets/README.md`.
- **License:** the kit contains code ported from caelestia (GPL-3.0). A published vtnc must be GPL-3.0.

## Colors: matugen → the shell's tokens

- `services/Wallpapers.qml` runs `matugen image <wallpaper> -t <scheme> --source-color-index 0 --dry-run -j hex`
  on a wallpaper or scheme change and saves the whole output to `~/.cache/vtnc/matugen.json`: every role
  (50) of **both** schemes and the six tonal palettes (tones 0…100). A light / dark toggle doesn't re-run it.
- `theme/colorRoles.js` lists the shell's tokens (`primary`, `surfaceContainer`, …) with their M3 role and
  resolves a **spec**: `light:<role>` / `dark:<role>`, `tone:<palette>:<tone>`, `#rrggbb` or `oled`.
  The file also carries `luminance` (see Transparency above).
- `theme/Colors.qml` keeps the same token names; each one is the user's spec for the current mode
  (`Store.theme.colors[mode][token]`, saved in `~/.config/vtnc/appearance.json`, so presets carry it), else
  its role in that mode (`background`: `surface`).
- Settings → Appearance → Colors edits the mappings per mode; roles and tones follow the
  wallpaper, a hex doesn't. The user's own: dark `primary` / `overPrimary` = the light scheme's (the deep tone 40).
- Tests: `node theme/tests/colors.test.js`.

## ToDos

- The caelestia-inspired pass, stages 1–9 (the plan's tracker).
- Quick configs Iwidget: panels from the island (Wi-Fi, Bluetooth, power… — the user has ideas; 2026-10-09).

- **Stage D: Dwidgets redone in the Iwidget language (2026-10-11).**
  - One card colour, `theme.card`, for the island and the dashboard.
  - Quick configs and the toggles use Shapes / Two tones / Tone + Card. `QMark` is shared with the island, which
    gains Tone too. `QuickView` lays out marks or labels; `DwidgetCard` draws the card variants.
  - Per-entry colour, gap, weight and labels.
  - New sizes.
  - Panels bare in the three looks; Sliders redone (SliderView, Shapes / Two tones / Tone + Card; wavy / percent options).
  - Calendar redone (CalendarView, Shapes / Two tones / Tone + Card): month / week / today by the size; today's mark an
    M3 shape of the day, a tone square or a heavier number with a dot; options colour / weight / title / weekdays.
  - Media redone (MediaView, Shapes / Two tones / Tone / Disc + Card): strip / square / wide / block / tall by the size;
    Cover, Type and Android 16 dropped (migrated); options colour / art / wavy / times.
