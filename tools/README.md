# vtnc dev tools

The `dev` branch = `main` + this folder. `main` is the shell that runs (`~/.config/quickshell/vtnc`); these
tools live in a worktree of `dev` (`~/.local/src/vtnc-dev`) so Quickshell never loads them, and they work on
the live shell at `$VTNC` (default `~/.config/quickshell/vtnc`). Commit shell work on `main`; bring it here
with `git merge main` (main never touches `tools/`).

| Tool | What |
|---|---|
| `check` | before every commit: the node tests, forbidden patterns, the layer lint, a live reload + log diff (`--no-live`, `--restart`, `--strict-layers`); `known-log.txt` = accepted log noise |
| `layers.py` | the layer lint of the folder layout "by surface" (`-v` every import, `--strict`) |
| `jitter.py <video>` | the island's body and a text tracked frame by frame in a recording: stutter, rest wobble, tremor |
| `probe/` | the offscreen probe: renders components to PNGs on stubs (tester-visual uses it) |

The frame-rate meter is in `main` (it runs inside the shell): `qs -c vtnc ipc call shell perf on`, then
`qs log -c vtnc -f | grep perf`.
