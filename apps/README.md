# Island apps

Each app lives in `apps/<id>/`: `App.qml` (a `VtncApp`: appId, title, icon, view) and `View.qml` (a
FocusScope; `opened(args)` / `closed()` are called on each open / close). Register it in
`apps/AppRegistry.qml` and give it an `AppTarget` in `core/Ipc.qml` (`qs -c vtnc ipc call <id> toggle`).

## Look (2026-10-17)
One global look for every app: Appearance → General → Apps (`theme.appStyle`: shapes / tones / tone),
read as `K.Kit.appStyle` and `K.Kit.appLook` (the Quick panels' look object, so `PanelColors` and
`ActionGroup` from `dwidgets/quick/panels/` work as they are). No per-app look option.

Lists share `apps/common/`:
- `RowHighlight.qml`, a ListView `highlight`: Shapes the container plus the `FocusShape` behind the
  row's icon, Two tones a tinted container, Tone a 3 px bar.
- `FocusShape.qml`, the random M3 shape of the current item (the workspaces Iwidget's): `next()` on
  every move, `reshuffle()` (no morph) on open.
- Pattern: the current row grows (`K.Anim` FastSpatial) to show an `ActionGroup` of what it can do; give
  it `idleFill: K.Kit.expressive.high` in Shapes (the row is the container).

## Apps
| id | Keys (Hyprland, hypr/vtnc/keybinds.lua) | Notes |
|---|---|---|
| launcher | Super | the current app grows with its desktop actions (Ctrl+1…3) |
| session, tools | Super+Esc, Super+S | `components/ActionRow.qml`; Shapes: one sliding M3 shape |
| wallpaper | Super+, | random · scheme ‹ › · light/dark in one group |
| notifications | Super+N | `services/Notifications.qml` history, grouped by app; the bell: left opens, right DND |
| clipboard | Super+V | `services/Clipboard.qml`: cliphist (the shell runs `wl-paste --watch cliphist store`), pins in state.json |
| notes | Super+Shift+N | `.md` files in the notes folder; title = first line; autosave 500 ms; Markdown preview |
| helper | Super+/ | tabs About · Keys · Mouse · CLI · IPC · Glossary (`apps/helper/HelperList.qml`; keys read from keybinds.lua, IPC live from `qs ipc show`) |
| dino | — | Chrome's dino run in the theme's colours (pixel sprites, `sprites.js`); high score and the last 20 runs in state.json |

## Options and state
- Options: `system.json` → `apps.<id>` (`Store.appOptions`), Settings → Apps.
- Remembered state: `state.json` → `apps.<id>` (`Store.appGet/appSet`): clipboard pins, notes pins and the last
  note, the dino high score, the settings page.

## On the dashboard
Notifications, Clipboard, Notes and Dino run have summary Dwidgets (`dwidgets/summary/`, see `dwidgets/README.md`).
They open their app with args: Notifications `{ id }` (that one current), Notes `{ file }` or `{ new: true }`, Dino
`{ play: true }` (a new run).
