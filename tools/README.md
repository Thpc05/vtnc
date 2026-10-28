# vtnc dev tools

Two Quickshell configs, one repo:
- `~/.config/quickshell/vtnc-dev`, branch `dev` = the shell + this folder: all work happens and is committed
  here, and it runs as `qs -c vtnc-dev` (Quickshell never loads `tools/`; nothing imports it).
- `~/.config/quickshell/vtnc`, branch `main` = the express version, `qs -c vtnc`: it only receives releases,
  `tools/release` (a merge of dev with `tools/` left out).

Both share the shell id `vtnc` (its state and config in `~/.config/vtnc`): run one at a time
(`qs kill -c vtnc; qs -c vtnc-dev -d`). The tools work on the shell around them, or `$VTNC`.

| Tool | What |
|---|---|
| `check` | before every commit: the node tests, forbidden patterns, the layer lint, a live reload + log diff (`--no-live`, `--restart`, `--strict-layers`); `known-log.txt` = accepted log noise |
| `layers.py` | the layer lint of the folder layout "by surface" (`-v` every import, `--strict`) |
| `jitter.py <video>` | the island's body and a text tracked frame by frame in a recording: stutter, rest wobble, tremor |
| `probe/` | the offscreen probe: renders components to PNGs on stubs (tester-visual uses it) |
| `release` | dev → main: merges dev into the main worktree, leaving `tools/` out |

The frame-rate meter is in the shell itself: `qs -c vtnc-dev ipc call shell perf on`, then
`qs log -c vtnc-dev -f | grep perf`.
