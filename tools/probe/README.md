# Offscreen probe

Renders parts of the shell to PNGs without touching the running shell or its files: a tiny Quickshell config
built in a temporary folder loads the real `kit/`, `components/`, `dwidgets/` and `iwidgets/` (symlinks, read only)
on stubs (the user's matugen palette, a read-only Store, fake player / battery / audio).

## Run

```sh
tools/probe/render.sh tools/probe/examples/battery.qml          # → $PROBE_DIR/battery-dark.png, -light.png
tools/probe/render.sh my-gallery.qml /tmp/shots/x               # → /tmp/shots/x-dark.png, x-light.png
```

`render.sh` builds `probe-dark/` and `probe-light/` in `PROBE_DIR` with `mkprobe.py` (base stubs) and
`mkisland.py` (island stubs, Iwidget registry), copies the gallery there and runs it with:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl qs -p <gallery>.qml
```

Shaders (the blob surface) and MultiEffect masks render only on rhi + opengl: the software backend ignores
them and vulkan hangs offscreen.

## Environment

| Variable | Default | What |
|---|---|---|
| `PROBE_DIR` | `$XDG_RUNTIME_DIR/vtnc-probe` | where the probes are built; refused inside the shell's code |
| `PROBE_WIDGETS` | `battery tray volume` | Iwidgets kept in the probe's WidgetRegistry (others may need more stubs) |
| `PROBE_ISLAND` | `{}` | JSON for `Store.island` (a widget's options, e.g. `{"battery":{"compact":{"show":"both"}}}`) |
| `PROBE_BATT` | `34` | battery stub: `<percent>[,charging]` |
| `PROBE_ART` / `PROBE_PAUSED` | | player stub: cover image path / `1` = paused |

## A gallery

A `ShellRoot` with a `FloatingWindow`; after a moment it calls `grabToImage` on its content and saves to
`Quickshell.env("OUT")`, then `Qt.quit()` (see `examples/battery.qml`). Import what you render: `qs.theme`,
`qs.kit as K`, `qs.iwidgets` (`IwidgetFrame`), `qs.dwidgets`…

## Safety

- The scripts write only in the probe dir: `mkprobe.py` refuses a folder inside the shell, or a non-empty
  folder without its `.vtnc-probe` mark; `mkisland.py` refuses a folder that isn't a probe; `render.sh`
  checks the folder before `cd`.
- The offscreen render uses whole pixels at scale 1: it can't show the ~1 px icon offsets; measure those live
  with `grim`.
