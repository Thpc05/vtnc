# Dwidgets: the dashboard grid

This folder is the base of the dashboard. **Read this first** before changing the dashboard, adding a
widget or picking one of the open options below. Keep it up to date whenever a contract changes.

## Vocabulary

| Word | Meaning |
|---|---|
| **Dwidget** | A dashboard widget (`dwidgets/<id>/Widget.qml`). Island widgets are *iwidgets*. |
| **Qwidget** | A mini widget inside Quick configs (Dwidget and Iwidget): a toggle (Wi-Fi, caffeine…), an action (a tool, a session action, the next colour scheme) or an app (a launch target). |
| **instance** | One Qwidget in a Quick configs list. Qwidgets repeat (up to `MAX_ITEMS`), so each instance has a key (`caffeine#2`) and its own config (an App's `target`). |
| **launch target** | A string naming what to open (`core/launch.js`): `vtnc:<app>`, `vtnc:settings/<page>`, `desktop:<entry id>`. |
| **cell** | The grid unit. A Dwidget spans `w×h` cells. |
| **entry** | One Dwidget placed on the dashboard: one item of `dashboard.widgets`. |
| **style** | One look of a Dwidget. Each style lists the sizes it allows. |
| **look** | An entry's `idle: { style, size }`. Every look is a style (2026-09-27: the configurable expanded mode is gone; its looks moved into styles, and panels show only expanded). |
| **expand** | Only the Dwidgets that need it expand, set in the catalog (`expand: { size, trigger }`): the Wi-Fi and Bluetooth toggles (double click → their list, 4x6) and the debug placeholder (click → 4x3). Their entries may pick another event (`expandOn`); the size is fixed. The expanded rect keeps the same style. |

## Files

| File | Role |
|---|---|
| `catalog.js` | The source of truth: Dwidgets, their styles and sizes, and their default modes and event. |
| `layout.js` | A pure layout engine: entries plus the expanded entry go in, rects in cells come out. |
| `Dwidget.qml` | The base type every Dwidget extends: the contract. |
| `DwidgetFace.qml` | A Dwidget drawn as a simple box (icon, title, size): editor fallback and drag ghost. |
| `<id>/Widget.qml` | One Dwidget. Its helpers live next to it. |
| `tests/layout.test.js` | Tests for the engine and the catalog: `node dwidgets/tests/layout.test.js`. |
| `tests/merge.test.js` | Tests for `mergeDashboard`: `node dwidgets/tests/merge.test.js`. |
| `tests/qwidgets.test.js` | Tests for the Qwidget catalog: `node dwidgets/tests/qwidgets.test.js`. |
| `core/DwidgetRegistry.qml` | Merges the catalog with the components; imported by the dashboard and settings. |
| `apps/dashboard/View.qml` | The dashboard page. It holds which entry is expanded, and Esc collapses it. |
| `apps/dashboard/DashboardGrid.qml` | Runs the engine and places one `Cell` per entry. Its implicit size is the grid's size. |
| `apps/dashboard/Cell.qml` | Loads a Dwidget, animates it to its rect, and handles the click/hover triggers and dimming. Each time the dashboard opens (`View.opened` → `grid.enter()`) the cells come in one after another in reading order (`grid.rank`): a fade and an 8 px rise, timed against the island page's own fade. |
| `apps/settings/pages/dashboard/General.qml` | Settings → Dashboard → General: expand mode, cell size, gap, demo/restore/factory layout. |
| `apps/settings/pages/dashboard/Layout.qml` | Settings → Dashboard → Layout: the layout editor (below). |
| `core/StateMerge.js` `mergeDashboard` | Validates `dashboard.widgets` against the catalog. |

## Catalog (`catalog.js`)

```js
WIDGETS.<id> = {
  title, icon,                       // icon: a property name of theme/Icons.qml
  styles: [{
    id, title,
    sizes: ["2x2", "4x2"]            // "WxH" in cells; the first is the style's default
  }],
  defaults: {                        // a new entry
    idle: { style, size },
    options: {}
  },
  expand: { size, trigger }          // only the Dwidgets that need to expand (optional)
    options: {}
  },
  debug: true,                       // optional: never offered in Off (placeholder)
  preview: false                     // optional: the editor shows a simple box instead of the real Dwidget
}
```

Helpers: `has`, `style`, `validStyle`, `validSize`, `parseSize("3x2") → {w:3, h:2}`,
`validMode(id, mode, fallback)` (a bad style gives the fallback's; a size the style doesn't allow gives the
fallback's when valid, else the style's first),
`expandedSize(entry)`, `trigger(entry)` (`"none"` when invalid), `defaultEntry(id, uid, x, y)`.
Constants: `MODES` (the expand modes) and `TRIGGERS`.

## State (`Store.dashboard`, `~/.config/vtnc/dashboard.json`, factory `defaults/config/dashboard.json`)

```json
"dashboard": {
  "cell": 80, "gap": 8, "expandMode": "over",
  "widgets": [
    { "uid": "quick", "id": "quick", "idle": { "style": "shapes", "size": "4x1" },
      "x": 3, "y": 0, "off": false, "options": {} }
  ]
}
```

- **`uid`** is unique per entry, so the same Dwidget can appear twice. `id` is the catalog id.
- **`x`, `y`** are in cells. Each mode's **`size`** must be one of its style's `sizes`. The grid lays out the
  **idle** size.
- **Per-entry event, only for expanding Dwidgets:** `expandOn` (click · doubleclick · hover · none) is kept only
  when the catalog has `expand` and the value is valid; otherwise the catalog's trigger applies. `expanded` from
  older states is dropped.
- **Migration:** the old one-style shape (`style` / `size` at the top level) becomes `idle`, and `expanded` gets the
  Dwidget's default. The old `""` / `self` event becomes explicit (the old placeholder defaults were box →
  click, tall → hover; everything else → none).
- **`options`** is free per Dwidget (the Dwidget reads it; nothing validates its content yet).
- **`off`** set to `true` means the entry isn't on the dashboard. It waits in the editor's Off area and keeps its
  style, size and options. Only `!off` entries are laid out (`DashboardGrid.placed`).
- **`mergeDashboard`** drops unknown ids and duplicate uids, and falls back to the catalog for a bad style, size,
  trigger, position, off flag or options.
  - **Only the original may be off** (2026-10-11, as the island): the original is uid = id, Duplicate's copies
    `<id>-2`…. An off copy is dropped by the merge, or stands in for a missing original. Taking a copy off deletes
    it (the editor's "Delete copy"), and the editor tags copies.
  - Every catalog Dwidget **without its original** (no entry at all, or only copies) gets an off original, so Off
    always offers it. Catalog entries with `debug: true` are the exception.
  - Overlaps are left to the engine.
- **Saving:** `widgets` is a `var` inside a nested JsonObject, so **reassign** the whole array. Store saves it
  through an explicit Connections.
- **Demo backup:** while the demo layout is on, the user's layout is kept in `apps.settings.dashboardBackup`.

## Layout engine (`layout.js`)

`solve(items, expanded, mode) → { rects: { uid: {x, y, w, h, z, hidden} }, cols, rows }`, all in cells. It is
pure, so the final size is known before anything animates. The island body morphs to the grid's size the same
way it morphs to any page.

**Base pass.** Every entry sits at its `x, y`. An entry that collides with one already placed is pushed down
until it's free. Entries are placed top to bottom (by `y`, then `x`, then list order), so pushes cascade.
Nothing is compacted upward: the user's positions are the truth, and holes stay.

**Expand modes** (`dashboard.expandMode`). The expanded rect takes **exactly** the expanded size. A smaller one
keeps its top-left corner: under over the freed space stays empty, and under push nothing is pulled up.
Under over every other cell dims alike to 40 %, the ones under the raised cell too (user, 2026-10-17; they were
faded out for a day). The covered ones take no input (`Cell.qml` `covered`, `grid.raisedCell`). No backing: an opaque one showed through a
translucent island (R1 area 3, 2026-10-15; the earlier backing, shown while `settling`, is gone).

**Cards' colour** (`theme.card`, one setting for the island and the dashboard since 2026-10-11: Settings → Appearance → Colors → Cards; `catalog.js` `CARDS`): neutral
(surfaceContainer, factory), container (primaryContainer), tinted (surfaceContainer with a 14 % primary tint) or
primary. It's one palette for every Dwidget with a card: `K.Kit.card` (`kit/Kit.qml`), and `K.Kit.bare` for the
no-card styles, with the same roles: fill · over / overVariant · accent / overAccent · off / high · selected /
overSelected · tonal / overTonal · track · weak / faint. A Dwidget picks `pal: card ? K.Kit.card : K.Kit.bare` and
draws only with its roles (on primary the accent turns onPrimary, so today, on marks, fills and the play button
invert); the panels get it through `look.panel.pal`.

```
base        over (B → 2x2)   push (B → 2x2)   takeover (B)
A A B .     A A B B          A A B B          B B B B
C C D D     C C B B          C C B B          B B B B
            (D under B)      . . D D          (A C D fade out)
```
(These are real engine outputs. Regenerate them with a few lines of node if the rules change.)

- **`over`:** it grows over its neighbours (`z` 1). It keeps its top-left corner when the grid has room,
  otherwise its right/bottom edge, otherwise it starts at 0 and **grows the grid** (to the right and down).
  Neighbours stay put and dim alike.
- **`push`:** it grows right and down from its origin, moving left only to stay inside the current columns.
  Everything it overlaps is pushed down by the base pass, so the grid grows **downward**.
- **`takeover`:** it takes the whole grid (at least its expanded size). The others get `hidden`: they fade out
  in place and are not moved.

**Editing functions**, used by the settings editor:
- **`drop(items, uid, x, y, w, h) → { uid: {x, y} }`:** the dropped (or resized) item stays exactly at x/y/w/h,
  and the others are re-placed around it by the base pass (pushed down). It returns every position, and the
  editor saves **all** of them, so what's saved is what's shown.
- **`nearestSize(sizes, w, h)`:** the allowed size closest to w×h (ties go to the smaller area). This is the
  resize knob.
- **`firstFree(items, w, h, cols)`:** the first free spot, row by row. This is "Add" from Off.

## Settings editor (Dashboard → Layout)

- **Canvas:** the real `DashboardGrid` with `editing: true`, so the Dwidgets render but take no input and write
  nothing.
  - It uses the real cell size and gap, scaled down only to fit, with one spare column and row to drop into.
  - Below a 0.6 scale, or for a Dwidget with `preview: false`, the cells show `DwidgetFace` instead
    (`DashboardGrid.simple`, `Cell.simple`).
- **Handles:** a transparent overlay per placed entry.
  - A click selects it.
  - A drag moves a ghost. The drop outline is the entry's size at the nearest cell, and the move happens on drop
    through `drop()`.
  - The corner knob previews and applies `nearestSize`.
- **Off:** chips of the off entries. A chip dragged onto the canvas is placed where it's dropped, and a cell
  dropped on Off gets `off: true`.
- **Detail panel:**
  - Add / Take off, and Duplicate (the copy gets uid `<id>-2`, `-3`…, and goes on the dashboard at the first free
    spot).
  - **Idle:** Style (when there are several) and Size. The canvas and its knob edit this mode.
  - **Look:** Style, Size, and "Expand on" (only for
    Dwidgets that expand: Double click · Click · Hover · Never).
  - Changing a mode's style falls back to that style's first size if the old one isn't allowed.
  - `page.options[id]`: a slot for per-Dwidget option components.
- **Saving:** every edit rewrites the whole `dashboard.widgets` array, through `Qt.callLater` after a drop
  (rewriting rebuilds the handles).

## Quick configs (`quick/`)

The first real Dwidget. It shows the **Qwidgets** chosen in `options.items`.

**A wildcard (2026-10-11, user):** a customisable dashboard inside the dashboard. The user builds their own Session,
Tools or apps Dwidget out of it.
- **Kinds** (`qwidgets.js`):
  - toggles: Wi-Fi … light mode, Transparency;
  - actions: Colour scheme (next; right click back), one per screen tool, one per session action;
  - apps: App, which opens the instance's `target`, and Settings, a fixed `vtnc:settings`.
- **Groups** (2026-10-11, simplified by the user): Connections (Wi-Fi, Bluetooth) · Appearance (temperature,
  light mode, colour scheme, transparency) · System (caffeine, do not disturb, game mode, power profile) · Sound
  (microphone, mixer) · Apps · Tools · Session. The editor's "Add" shows one group at a time (tabs).
- **Repeats and instances:**
  - `options.items` holds ids or instance objects (`{ id: "app", target: "desktop:kitty" }`), repeats allowed, at
    most `MAX_ITEMS` (24);
  - `items(options, island)` gives `{ key, id, config }`; `raw()` gives the stored list.
- **`Models.qml`** keeps one model per instance key (created and destroyed one by one, with its config updated in
  place), for the Dwidget and the island's Quick configs Iwidget (which leaves the panel-only Mixer out). The
  views lay out keys; `idOf(key)` gets the catalog id.
- **Shared actions:** Tools and Session read their action lists from `apps/tools/actions.js` and
  `apps/session/actions.js`, the same lists their apps use. `core/Actions.qml` runs them after the island closes.
  The session actions that end the session arm on the first click and run on a second within 3 s.
- **Apps:**
  - `core/Launch.qml` runs and describes launch targets (`core/launch.js`, tested in `core/tests/launch.test.js`);
  - IPC `launch run <target>` (the future CLI's `vtnc open`);
  - the settings pick one with `apps/settings/controls/TargetPicker.qml`, reusable for future dashboard tabs.
- **IPC:** `transparency on|off|toggle`, `scheme next|previous|set <name>`.

**A Dwidget's id is its purpose (what it does); the style is what makes it (how it looks).** Every style is
independent, so one Dwidget can look completely different on two dashboards.

- **Styles** (2026-10-11, redone in the Iwidget family): `shapes` · `tones` (Two tones) · `tone`, each with a
  `<look>Card` variant (the no-card one is the parent and default; `cards()` in `catalog.js`).
  - `quick/QMark.qml` draws one mark, shared with the island's Quick configs Iwidget:
    - shapes: off a rounded square, on an accent circle; with Random shapes (each Dwidget's `options.randomShapes`, default on,
      in its Layout options; 2026-10-16, per Dwidget since 2026-10-17, user) off a circle, on an accent M3 shape (`RandomShape.qml`: the same
      for every mark as the dashboard opens, `DashboardShape.qml`; a new one when it turns on, connects or
      disconnects, i.e. its symbol changes);
    - Two tones: off a weak bare icon, on a square in the tone;
    - Tone: no fills, the icon in the tone, filled and heavier when on;
    - an armed session action in the error colour.
  - `quick/QuickView.qml` lays them out: marks alone, or labels (mark + name + state) when the size has room. There
    are no boxes behind them, as on the island.
  - `DwidgetCard.qml` draws the card variants.
- **Options per entry** (Layout side panel, `LookOptions.qml`):
  - `color`: the Two tones / Tone colour role, as the tray tint (`quick/ToneColors.qml`);
  - `gap`;
  - `weight`: 300…1500, emboldened past 700;
  - `labels`: auto / on / off.
- **Migration:** the old `shapesNoCard` / `tonesNoCard` become `shapes` / `tones` (`RENAMED` in `catalog.js`). The old
  card ids `shapes` / `tones` are reused, so they become the no-card styles.
- **Arrangement:** no option; the size decides (`qwidgets.js`: `arrange()` pills or icons; `split()` and
  `squares()` are shared).
  - Pills (the toggle, then the name and state) when rows of 44 px fit, as few per row as fit the height
    (one per row in a tall rect), each at least 120 px wide.
  - Else icons: the rows chosen for the biggest, centered.
- **Input** (`quick/QInput.qml`, every style): a click toggles (the Mixer opens its panel), a right click opens
  the panel; hover and the ripple from `K.StateLayer`.
- **Panels** (2026-10-16, user's pick "hero do estado"; bare, no blocks, in the look of the Dwidget that opened
  them). `look.panel` carries `kind` (shapes / tones / tone), `pal`, `tone` / `overTone`, `strong` / `weak` / `faint`;
  `PanelColors` turns it into the colours (Shapes: palette roles, `off` = `pal.high`; tones / tone: the tone and its
  tints).
  - `PanelHeader`: back at the left, the Qwidget's switch (`PanelSwitch`, in the look; Tone a tint) at the right, no title.
  - `PanelHero`: what's on now, big: a 44 px QMark (32 compact: the Mixer's wide panel, or while a row is open),
    the name (17 px, shrinking to 14 before it elides) and its state, optional extra content (a slider), and its
    actions as one `ActionGroup`.
  - `ActionGroup`: a connected group spanning the width (pill ends, 4 px inner corners, 2 px gaps), the primary in
    the accent; `iconOnly` actions are narrow (Forget's bin, Log in's globe); a label that doesn't fit drops its
    icon; `perRow` wraps (presets).
  - `PanelSection`: a weak caption, a hairline and an optional action (rescan, spinning while busy).
  - `PanelRow`: 36 px, a 28 px QMark, the name (strong), the state at the right (weak), trailing marks; an open row
    sits on a faint fill (inset) and scrolls into view once grown.
  - Wi-Fi: the connected network (Disconnect, Log in when limited), then the others (open rows keyed by bssid:
    a password field when asked, Connect). Bluetooth: the connected device (battery; Disconnect, Forget), then the
    others (Connect / Disconnect, Pair or Forget). Power: the profile, then the others. Night light: the
    temperature with a slider, then the presets (3 per row). Mixer: the output (volume slider; the mark mutes)
    with its output / input rows, the apps beside them (icon mutes, slider).
  - One inset: the hero mark, captions and row marks at the content's left edge; switch, groups, refresh and
    trailing marks at its right edge.
- **Migration:** the old `options.layout` is dropped (`StateMerge.migrateQuick`).

**Adding a style:** add it to `catalog.js` (inside `cards()` for a Card variant), teach `QMark` / `QuickView` its look, and the Iwidget follows.

| File | Role |
|---|---|
| `quick/qwidgets.js` | The Qwidget catalog `{ title, icon, panel, kind, group, island?, tool?, action?, config? }`, `GROUPS`, `MAX_ITEMS`, `DEFAULT_ITEMS`, `raw` / `items(options, island)` (instances, repeats kept), `available(shown, island)`, `idOf`. Tested in `tests/qwidgets.test.js`. |
| `quick/Models.qml` | One model per instance key (the Dwidget and the island Iwidget). |
| `quick/Qwidget.qml` | The model contract: `title`, `icon` (the Phosphor glyph for its current state), `symbol` (the same as a Material Symbols name), `active`, `available`, `status`, `panel` (a Component), `action` (a header button, e.g. rescan). Each model defines `function toggle()`. |
| `quick/qwidgets/<Id>.qml` | One model per Qwidget, bound to its service (NetworkService, BluetoothService, NightLightClient, CaffeineClient, GameModeClient, `Notifications.silent`, `PowerProfiles` from Quickshell.Services.UPower, `Audio.source`, `Store.theme.light`). |
| `quick/QuickView.qml` · `QMark.qml` · `ToneColors.qml` | The layout (marks / labels), the mark (shared with the island), the tone colours. |
| `DwidgetCard.qml` | The card behind a Card variant (the island card's look: pill / extraLarge, Kit.card, compact padding). |
| `quick/QInput.qml` | The shared input: click toggles, right click opens the panel. |
| `kit/` | The style kit: `Kit` (tokens: rounding, spacing, padding, fonts, M3 motion), `Anim`, `CAnim`, `StyledRect`, `StyledText`, `MaterialIcon`, `StateLayer`. Import as `qs.kit as K` (names clash with `qs.components`). |
| `quick/panels/` | `PanelColors`, `PanelHeader` (back, switch), `PanelSwitch`, `PanelHero`, `ActionGroup`, `PanelSection`, `PanelRow`, `PasswordField`, and the panels: Wi-Fi, Bluetooth, Mixer, NightLight, Power. |
| `apps/settings/pages/dashboard/ItemsOptions.qml` | The items editor in the Layout side panels (dashboard Quick configs and Sliders, island Quick configs). Shown chips: drag to reorder; click to select, then remove it or pick an App's target (TargetPicker). Add: one group at a time (tabs), click a chip to add it. It edits by position, so repeats work. |

**How a Qwidget reacts:**
- A click toggles it.
- **Right-click** on a Qwidget with `panel`, or a click on a tile's name, calls `openPanel(id)`. There is no
  caret; the Qwidget settings carry a hint about this.
  - It works **only when the entry has an expand event** (`expandable`).
  - It expands the Dwidget if it isn't already expanded, and the panel shows in the expanded rect.
- While `expanded && panelId`, the content fades through to the panel page (out 0–30 %, in 30–80 %).
- Back collapses the Dwidget if the panel expanded it; otherwise it returns to the expanded look. `panelId`
  clears after a collapse's fade.
- **Idle ↔ expanded** fades the content through as well: `shownStyle` swaps at the dip. When it's hidden behind
  the panel, it swaps at once.
- With `editing`, nothing reacts.

**Adding a Qwidget:**
1. Add it to `QWIDGETS`.
2. Create `quick/qwidgets/<Id>.qml` (extends `Qwidget`, defines `toggle()`, optionally a `panel`).
3. Instantiate it in `quick/Widget.qml` and add it to `models`.

## Dwidget contract (`Dwidget.qml`)

`Cell.qml` sets these properties, and sizes the Dwidget to its rect with `anchors.fill`:

| Property | Meaning |
|---|---|
| `style` | The style id to render now: the idle or the expanded mode's. |
| `size` | `{ w, h }` in cells, the **current** rect (the expanded size while expanded). |
| `expanded` | Whether this entry is the expanded one. |
| `expandable` | Whether the entry has an expand event (not `none`). |
| `trigger` | The entry's expand event (`DwidgetRegistry.trigger`): click · doubleclick · hover · none. |
| `options` | The entry's options. Read-only; write them back through the state. |
| `editing` | True in a settings preview: render only, no service writes, no side effects. |

It emits `expandRequest(bool on)` (for example, to show a panel in the expanded rect). It only counts when
`expandable`.

A Dwidget must **fill whatever rect it gets**: the rect animates between sizes, and the cell clips it.

## Expansion flow

1. A trigger fires:
   - `click`: a TapHandler on the cell toggles it. Taps taken by the Dwidget's own controls don't count.
   - `hover`: expands after 150 ms and collapses 250 ms after leaving.
   - `none` (Never): nothing fires, and the Dwidget's own `expandRequest` is ignored too.
   - The Dwidget's own `expandRequest(on)` fires when `expandable` (the Quick configs panels).
2. `DashboardGrid.expandRequest(uid, on)` reaches `View.expand(uid, on)`. At most one entry is expanded.
   Expanding another one collapses the first.
3. `View.expand` sets `expandedUid`.
4. The engine re-solves. Every cell animates x/y/width/height on the island body's curve (`K.Anim`
   DefaultSpatial, both ways), the grid's implicit size changes, and the island body follows with its morph.
   (The raised cell's jelly was removed on 2026-10-27, with the island's.)
5. The expanded entry collapses on:
   - Esc (then a second Esc closes the dashboard);
   - a click on the empty grid, or on another cell (in over / takeover the other cells take no input while one
     is expanded, so a toggle next to it doesn't flip);
   - a click on the entry again (click trigger);
   - the pointer leaving (hover trigger);
   - its own request (`expandRequest(false)`);
   - the dashboard closing.

## Adding things

- **A Dwidget:**
  1. Create `dwidgets/<id>/Widget.qml` extending `Dwidget` (`import qs.dwidgets`).
  2. Add it to `catalog.js`.
  3. Import it in `core/DwidgetRegistry.qml` and add it to `components` and to a `Component`.
  4. Optionally, add it to the default layout in `defaults/config/dashboard.json`. Otherwise the merge appends
     it to Off.
  5. Run both test files: they check every catalog entry is well formed.
- **Its options:** make a component and map it in `page.options` in `apps/settings/pages/dashboard/Layout.qml`.
  The Dwidget reads them from `options`.
- **A style:** add it to the Dwidget's `styles` and render it when `style` is its id.
- **A size:** add it to the style's `sizes`. Both modes can use it, and the Dwidget must still fill the new rect.
- **A trigger or an expand mode:** add it to `TRIGGERS` or `MODES` (the StateMerge ENUMS follow them), then
  handle it in `Cell.qml` or `layout.js`, and add tests.

## Open questions (the base supports every option; the user decides after trying it)

| Question | Where it's switched |
|---|---|
| The expand mode: over, push or takeover | `dashboard.expandMode`, Settings → Dashboard → Expand mode |
| The cards' colour: neutral, container, tinted or primary | `theme.card`, Settings → Appearance → Colors → Cards (one for the island and the dashboard since 2026-10-11) |
| The expand event | The catalog's `expand.trigger`, overridable per entry (`expandOn`, Layout → "Expand on"); only Dwidgets with `expand` |
| How many styles and sizes per Dwidget | `catalog.js` |
| Size editing | Both exist (the knob and the chips); both use `sizes` |
| Whether the mixer is a volume style or its own Dwidget | A Qwidget (2026-09-27): in Quick configs, or its own Dwidget like Wi-Fi / Bluetooth |

## Types (2026-10-27, user; the vault's `dwidget types` definition)
1. **Toggles** (`toggle/Widget.qml`, `qid`): wifi · bluetooth · mixer · colorScheme · powerProfile · wallpaper.
   One Qwidget with **a panel: every toggle must have one** (no panel, not a toggle; it stays a Quick configs
   item). 1x1…2x2 the compact toggle; 3x3…6x7 the panel is the face (`panelFace`: no back, no click event).
2. **Summaries** (`summary/Widget.qml`, `kind`): notifications · clipboard · notes · dino. An app's data, a
   badge or a list; they never expand.
3. **Collections**: quick (Qwidgets) · sliders (Swidgets): items the user picks and orders.
4. **Singles**: media · calendar · image · clock · visualizer, each its own component and layouts by size.
- Outside: placeholder (debug). All in the Iwidget look family (Shapes · Two tones · Tone, each + Card; media
  also Disc; image just Image + Card; visualizer Bars · Dots · Shapes + Card).

## Styles per Dwidget (2026-09-27)

**No card by default (user, 2026-10-08):** where a style comes with and without a card, the no-card one is the
parent in the style tree and the catalog default; the card one is its "Card" variant (ids kept).

The user's final list, in catalog order. The first one is the default. The "(no card)" variants are the same
style without its card.

**The vtnc (One UI) styles were dropped on 2026-09-29**: entries using them become `expressive` (size kept
when it fits). The style selector stays, even with one style.

**Style tree:** a catalog style with `group` is a variant of that style; Settings → Dashboard → Layout shows *Style* (the styles without a group) and *Variant* (the style and its variants, by their `variant` label).

| Dwidget | Styles |
|---|---|
| media | The Iwidget family (2026-10-11): `shapes` · `tones` · `tone` and `disc` (the extra, as the island's: the art a record turning while playing, its progress a wavy ring around it when ≥ 72 px), each + `Card`, drawn by `media/MediaView.qml` on `MediaState` / `Art` / `Picker`. Shapes: play an accent rounded square → circle while playing, prev / next on `pal.off` squares; Two tones: the title bold in the tone, the rest a weak tone, play bare → a tone square while playing; Tone: all in the tone, no fills. The size picks the layout: a row tall a **strip** (art · texts · controls), at least 1.6× wider **wide** (the art left: 4x2, 5x2, 6x2, 5x3, 6x3), clearly taller **tall** (the art big on top: 3x4), else **block** (2x2, 3x2, 3x3, 4x3, 4x4, 5x4: the art as big as the height leaves, prev · play · next in a row beside it when they fit, else play alone (the art keeps its size), the texts, progress and times under). Options: `color`, `art`, `wavy`, `times`. The wheel skips; a right click opens the player picker. Old looks migrate: cover / android → shapesCard, type → tonesCard, typeNoCard → tones, discNoCard → disc (the old card `disc` keeps its id: no card now) |
| quick | `shapes` · `tones` · `tone`, each + `Card` (see Quick configs; 2026-10-11) |
| mixer | a toggle Dwidget (see Toggles): shapes / tones (the toggle; its click opens the mixer panel, 6x7: `expandOn` defaults to click) |
| sliders | The Iwidget family (2026-10-11): `shapes` · `tones` · `tone`, each + `Card`, drawn by `sliders/SliderView.qml` (the island volume's sibling). Each Swidget is a mark (its action: mute, sync, on / off; Shapes an accent circle / rounded square, Two tones a tone square, Tone bare), a K.M3Slider (Shapes medium accent, Two tones thick in the tone, Tone thin) and its percent. Rows stacked in a wide rect, columns in a tall one. Options: `color`, `wavy` (the tracks thin and wave while music plays), `number`. Old looks migrate: inset → shapes, tonesNoCard → tones, wavyNoCard → tone, wavy → toneCard |
| calendar | The Iwidget family (2026-10-11): `shapes` · `tones` · `tone`, each + `Card`, drawn by `calendar/CalendarView.qml`. The size picks the layout: 3x3 and up a **month** (`MonthView`: "Oct 2026", one-letter weekdays, this month's days), a row 4…7 wide a **week** (`WeekView`: letters over numbers; the wheel moves a week), 1x1 / 2x1 / 1x2 / 2x2 **today** (`DayView`: the mark with the weekday and month beside or under it). Today's mark (`TodayMark`): Shapes an accent M3 shape (one per day, the same in every copy; with Random shapes, random on each open, in sync with the marks), Two tones a tone square (days gone by strong, to come weak: the earlier Expressive), Tone the number heavier with a dot under it. Numbers in Rubik, caps-centred (`CapText`). Options: `color`, `weight` (the days'), `title`, `weekdays`, `randomShapes`. Old ids migrate: expressiveNoCard → tones, expressive → tonesCard |

- **Summaries (`summary/Widget.qml`, 2026-10-17, user):** Notifications, Clipboard, Notes and (2026-10-27) Dino run
  on the dashboard (ids notifications, clipboard, notes, dino), one component with a `kind`, as the toggles' `qid`.
  Helper gets none.
  - Styles: the Iwidget family, `shapes` · `tones` · `tone`, each + `Card` (`summaryWidget()` in `catalog.js`).
    Options: `color`, `randomShapes` (the header mark). They never expand.
  - Sizes: 1x1 / 2x1 / 1x2 a **badge** (the mark, with the count and the title beside or under it when they fit; a
    click opens the app); 2x2 and up a **list** (`SummaryView`): a header (mark, title, count; a click opens the
    app; Notes adds a + for a new note, Dino a ▶ for a new run; under 150 px wide the mark goes) and as many rows
    as fit (`SummaryRow`: a 28 px lead, the title, a second line from 220 px wide when an item has one, the time
    or a pin). Rectangles 2 and 3 thick up to 8x2 / 2x8 (2026-10-27); a wide card flows the rows into columns of
    240 px or more.
  - A click on a row acts in place: a notification runs its default action (else opens Notifications on it,
    `{ id }`), a clipboard entry is copied (a check for a moment), a note opens in Notes (`{ file }`; + is
    `{ new: true }`), a Dino run opens the game (▶ is `{ play: true }`, a new run).
  - Data: `NotificationsSource` (this session's, the bell's count), `ClipboardSource` (`Clipboard.entries`),
    `NotesSource` (its own `NoteFiles`), `DinoSource` (the high score, the badge's number, and the last 20 runs,
    state.json `apps.dino.runs`, the best one marked), read again on each dashboard open (`DashboardShape.opens`).
- **Toggles (`toggle/Widget.qml`, 2026-09-27):** Wi-Fi, Bluetooth, Mixer and (2026-10-27) Color scheme, Power
  profile, Wallpaper are also their own Dwidgets (ids wifi, bluetooth, mixer, colorScheme, powerProfile,
  wallpaper), one component with a `qid`, reusing the Qwidget models and panels. Only Qwidgets with a panel
  can be toggles; the others go only in Quick configs. Scheme and wallpaper are actions (`switchable: false`:
  no switch in the panel header): `SchemePanel` (the mode as a group, the 9 schemes) and `WallpaperPanel`
  (Random / Open, the folder's thumbnails).
  - Styles (2026-10-11): the Quick configs family, `shapes` · `tones` · `tone`, each + `Card`. They are drawn by
    `QuickView` with the one Qwidget; the input is the toggle's own. Options: color, weight, labels.
  - Sizes: 1x1 (the mark), 2x1 / 3x1 / 2x2 (the mark, name and state), 1x2; and (2026-10-27, user) 3x3, 4x3,
    3x4, 4x4, 5x4, 4x5, 4x6, 5x5, 6x4, 6x5, 6x6, 6x7, where **the panel is the face**: always open, no back
    button, no click / expand event (`panelFace`; the Cell's trigger is "none" then). Was: panels only expanded
    (2026-09-27); old panel styles now keep their size when it's a panel size.
  - Compact panels (2026-10-27, user): no switch row on top; the hero's mark and name are the switch
    (`PanelHero.qwidget`, a click toggles a `switchable` Qwidget; Power profile, Scheme and Wallpaper aren't).
    The face has no header at all; opened by expanding, only the back arrow. A panel taller than its rect
    scrolls (the host's Flickable; fixed panels give an `implicitHeight`, list panels fill and scroll inside).
  - The Mixer's `options.show` (output · input · apps, at least one; Layout → its options) picks the parts of
    its panel (`MixerPanel.show`); the shown ones take the room.
  - They expand (their panel with a back button; Wi-Fi / Bluetooth 4x6, Mixer 6x7) on the entry's event (default double
    click; right-click always). Double click: the click toggles after the double-click interval. Click: the
    click expands (the switch is in the panel header). Hover / Never: the click toggles at once.
  - **Wi-Fi / Bluetooth with their name showing** (2026-10-15, user) ignore the entry's event for the left click:
    a click on the mark toggles, a click anywhere else opens the panel (`QuickView.onMark`). With the mark
    alone (1x1, 1x2) the event decides as above.
- **`doubleclick`** is an expand trigger (catalog `expand.trigger`). The Cell toggles on a double tap; Dwidgets
  whose own click acts (the toggles) handle it themselves and call `expandRequest`.
- **Sliders:** the **Swidgets** chosen in `options.items` (`sliders/swidgets.js`, like the Qwidgets): volume,
  microphone, brightness, night light (default volume + brightness). One model each in
  `sliders/swidgets/<Id>.qml` (`Swidget.qml`: symbol, iconFill, value, muted, ready; `set(v)`,
  `iconClicked()`). Tall rects put them side by side and vertical, close together; wide ones stack them.
  Every horizontal size has its vertical one (3x1 → 1x3). Icons: volume / mic mute, brightness toggles
  sync, night light turns it on / off (its value is the warmth, 6500 → 2500 K). Chosen in the
  Layout side panel (`ItemsOptions.qml`). Tested in `tests/swidgets.test.js`.
- **Mixer:** a Qwidget (`quick/qwidgets/Mixer.qml`: `opensPanel`, so a click opens its panel and never mutes, and the panel header has no switch; the status is the output device). In Quick configs its click expands the Dwidget to the panel too (the quick catalog `expand: { size: 6x5, trigger: none, panelOnly }`: no event of its own, no "Expand on" row; `hasEvent()`) whose panel is `quick/panels/MixerPanel.qml`: input devices, then output devices, then the apps (icon, name and percent above a thin M3 slider). Chips wrap, so every device shows. Like Wi-Fi / Bluetooth it can be its own Dwidget, which expands to the panel: a wide 6x5 rect with the devices at the left and the apps at the right (`wide`: width ≥ 1.1 × height; narrower it stacks). Old mixer entries fall back to the toggle's default look.
- **Kit pieces:** `K.M3Slider` (flat or wavy, bar or round thumb, a value
  bubble), `K.CookieShape`, `K.SliderInput`. `services/Cava.qml` feeds the island's Visualizer Iwidget (`iwidgets/visualizer`).
- The expressive containers are M3's `surfaceContainer` / `High` / `Highest` in both modes (since 2026-10-08, caelestia's roles).

- **Singles (2026-10-27, user):**
  - **Image** (`image/Widget.qml`): an image or a GIF (`AnimatedImage`; also any file without a still image's extension, read by its
    content) from the system, cropped to fill its rect and rounded by
    a mask (as `media/Art.qml`), squares 1x1…6x6 and (2026-10-27) rectangles both ways up to 6x4 / 4x6
    (`IMAGE_SIZES`), Image + Card. Options `path`, typed or picked with
    Browse… (`services/FilePicker.qml`: zenity, with Settings closed meanwhile since the island covers the
    screen, then reopened on that Dwidget; it opens on "All files", so names without an extension show), and `speed` (a GIF's, 0.25× … 2×, `AnimatedImage.speed`), `fit` (crop · fit · stretch) and `focus` (the part a crop keeps: center ·
    top · bottom · left · right). Or `source: "folder"` (2026-10-27, user): a random file from `folder`
    (`find`, not hidden ones, never the same twice in a row), changing on `change`: `open` (each dashboard
    open), `start` (each shell start) or `timer` (every `minutes`). The pick lives in `image/ImagePicks.qml`
    (a singleton, by the entry's uid: Cell.qml hands `uid` to a Dwidget that has one), so it outlives the
    Dwidget being made again in `apps/settings/pages/dashboard/ImageOptions.qml`.
  - **Clock** (`clock/Widget.qml`): shapes · tones · tone + Card, 2x1…4x2 and 3x3. The hour on its mark
    (Shapes an M3 shape, random with Random shapes; Two tones a tone square; Tone the hour heavier), the
    minutes beside it, the date under it when it's 110 px tall or more; Rubik, caps-centred. Options h24,
    seconds, date, color, randomShapes.
  - **Visualizer** (`visualizer/Widget.qml`): bars · dots · shapes + Card, 2x1…6x2. Its own levels from
    `services/Cava.qml` (one cava per bar count, shared with the island's when they match; only while
    something plays and it shows), smoothed per frame; dots are a column per band lit from the middle; shapes
    is `visualizer/BeatShape.qml` (2026-10-27, user: the rhythm): a beat detected in the bass (the lowest
    ~15 % of the bands jumping 1.35× over their ~0.4 s average, past a floor, one per 150 ms max) punches its
    size, picks another shape (spikier for a stronger beat) and kicks its turn; between beats it breathes
    with the energy, and with no beat for 2.5 s it follows the energy alone (the island's ladder). The levels
    are auto-gained over the music's recent peak (it follows a louder moment at once, ~halves in 4 s), so a
    quiet song moves it too. Shapes alternate round ↔ spiky families so each change shows. Options color, bars, alwaysShow, threshold (the activation level: Shapes
    start moving at it, Dots light past it; the island's Iwidget has `shapeThreshold` too, next to
    `dotThreshold`), and for Shapes `sensitivity` (low 1.6× · medium 1.35× · high 1.2× bass jump) `pulse` (the size's range: subtle 76–96 % · normal 62–100 % · strong 50–100 %) and
    `morph` (calm 0.6 s · normal 0.3 s · lively 0.15 s between shapes), and `shapeTrigger` (the bass jump, %, that
    changes the shape, apart from the pulse's beat; 35 % by default, lower = more changes); Bars hides for Shapes. `visualizer/VisualizerKeeper.qml` (started by shell.qml) keeps a cava per placed bar
    count running while music plays (10 s after it stops), with the dashboard closed, so an open shows it at
    once.
- **Offscreen probes:** `grabToImage` draws neither `ClippingRectangle` nor layer effects (MultiEffect masks):
  rounded images come out blank in a grab, not on screen.

## Status (2026-09-27)

- **`placeholder`** is a debug Dwidget, used by the demo layout (Settings → Dashboard → Demo layout).
- Every Dwidget is compat-free: the ambxst styles (`media full`, `calendar month`) were deleted on 2026-09-28.
- **Phase B, the layout editor,** is done: Dashboard → General / Layout, the Off area, the knob, the detail panel.
- **Next, phase C:** the remaining Dwidgets, one plan each: calendar, media, notification summary, weather,
  metrics. The apps' summaries (Notifications, Clipboard, Notes) exist since 2026-10-17.
