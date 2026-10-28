# Settings, state and presets

## Where things live

| Where | What | Who writes it |
|---|---|---|
| `~/.config/vtnc/island.json` | `island` (shape, widgets — entries `{ uid, id, section, compact, expanded }`, an Iwidget may repeat, Off keeps one of each —, clock, date, notifications, auto hide), `osd` | Settings → Island |
| `~/.config/vtnc/dashboard.json` | `dashboard` (grid, Dwidget entries) | Settings → Dashboard |
| `~/.config/vtnc/appearance.json` | `theme` (fonts, `scale`, `transparency`, anim, `scheme`, `light`, `colors`), `frame`, `wallpaper.current` | Settings → Appearance, the wallpaper app, light mode |
| `~/.config/vtnc/system.json` | `wallpapers` (dir, transition), `tools`, `audio`, `media`, `nightLight`, `hints`, `alerts`; `apps` (the island apps' options: notifications, clipboard, notes, dino; `Store.appOptions`) | Settings → System (audio, brightness, media, night light), Settings → Apps (also the wallpaper, tools and session apps' options, 2026-10-27) |
| `~/.config/vtnc/presets/<name>.json` | one preset each (below) | Settings → Presets |
| `~/.local/state/vtnc/state.json` | `controls` (toggles on/off), `player.pinned`, `presets.active`, `apps` (each app's UI memory, launcher usage) | the shell |
| `~/.local/share/vtnc/` | data (the future notification history, clipboard) | the shell |
| `~/.cache/vtnc/` | anything that can be rebuilt: matugen output, thumbnails, cover art, notifications | the shell |

- **The rule:** `~/.config` holds what the user sets, `~/.local/state` what the shell remembers, `~/.local/share` what
  the shell collects, and `~/.cache` what can be thrown away.
- **Factory defaults:** `defaults/config/<file>.json` and `defaults/state.json`. A missing file is copied from its
  factory file.
- **`core/Store.qml`:** one `ConfigFile` per file (`core/ConfigFile.qml`: load, validate against the factory
  file with `StateMerge.js`, complete, save 300 ms after a change). It exposes each top-level key as an alias:
  `Store.island`, `Store.theme`, `Store.controls`…
  - `Store.files.<name>` is the file itself (`json`, `defaults`, `replace()`, `signature()`).
- **Migration:** the old one-file state (`~/.local/state/vtnc/vtnc-state.json`, schema ≤ 4) is split once by
  `core/Migrate.js`:
  - the result becomes the preset "My setup" (and the active one);
  - the old file is kept as `vtnc-state.json.migrated`.

## Adding a setting
1. Pick the file by the table above. Put the value in its factory JSON, and add the property to that file's
   `JsonAdapter` in `core/Store.qml`.
2. A new top-level key also needs a `property alias` in the Store. Top-level names are unique across files.
3. An enum-like value goes in `StateMerge.js` `ENUMS`, keyed by the path inside its file.
4. Reassigned `var` values inside a nested `JsonObject` don't save by themselves. Call that file's `changed()`,
   as the Store does for the `widgets` arrays.

## Presets (`services/Presets.qml`, Settings → Presets)
- **A preset** is the whole style: `island.json`, `dashboard.json` and `appearance.json`, so it includes the
  wallpaper, scheme, light mode and color mapping. `system.json` and the state are never part of one.
  - The file holds `{ name, created, updated, config: { island, dashboard, appearance } }`.
- **Saved with or without the wallpaper** (a switch on the page). Without one, applying keeps the wallpaper
  shown. Before applying, the preset's wallpaper file is checked; a gone one also keeps the one shown (the page
  says so, and marks the preset "wallpaper missing").
- **"Default" is locked:** it can't be saved over, renamed or deleted (its content is also the factory
  defaults). It's a normal file otherwise.
- **No built-in preset** for now (user, 2026-09-29). With none active (`presets.active` = ""), nothing is
  modified, there's no Revert, and applying one asks first, since the current setup would be lost.
- **Active and modified:**
  - `Store.presets.active` is the preset applied last.
  - A part is **modified** when its file differs from the preset. The comparison uses `signature()`: the content
    merged with the defaults, only known keys, no `version`.
- **Where you can save:** only on the Presets page (Save, Save as new).
  - Every other page shows **Revert** in its header while its part (Island, Dashboard, Appearance) is modified.
  - Applying a preset while modified asks first: save and apply, discard and apply, or cancel.
- **Applying** replaces the three files. The Wallpapers service shows a changed `wallpaper.current` by itself,
  and matugen runs again for a new wallpaper or scheme.
- **IPC:** `qs -c vtnc ipc call preset list | active | apply <name> | save | revert`.
