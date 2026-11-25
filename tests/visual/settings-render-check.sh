#!/usr/bin/env bash
# Layer 4, 0.503: render the Settings window open on the Islands page, for a
# human to look at — not pixel-compared (decision 17.2). Unlike
# render-check.sh, this needs the real core/Config.qml singleton (Settings
# reads live island state from it), so it runs through `qs -p`, not plain
# qml6 — `qs` is what gives Quickshell.* and the qmldir singletons a real
# runtime context. Needs a real compositor for the same reason render-check.sh
# does: grabToImage never calls back under QT_QPA_PLATFORM=offscreen.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="${1:-$here/settings-render.png}"
# 0.507: qual página da Settings renderizar. Vazio mantém o padrão da
# própria Settings (Islands), que é o que a 0.503 pediu.
page="${VTNC_RENDER_PAGE:-}"
own_nest=""
tmp_config_dir=$(mktemp -d)
# `qs -p <file>` scopes qmldir import resolution to that file's own
# directory (same thing settings-write-boundary.sh works around) — a
# "../../settings" import from here isn't found unless the harness runs
# from vtnc-dev's own root instead.
harness="$root/.settings-render-test.qml"

cleanup() {
    if [[ -n "$own_nest" ]]; then
        "$root/tools/headless/nested.sh" stop "$own_nest" || true
        rm -f "$own_nest"
    fi
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./settings#./settings#' "$here/settings-render.qml" >"$harness"

if [[ -z "${NESTED_PID:-}" ]]; then
    own_nest=$(mktemp)
    if ! "$root/tools/headless/nested.sh" start "$own_nest"; then
        echo "FAIL: the nested test compositor did not come up."
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$own_nest"
fi

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 40, "h": 4 }, "layer": "top", "page": "clock" },
    { "name": "dock", "anchor": { "bottom": true, "left": true }, "offset": { "x": 2, "y": 2 }, "size": { "w": 20, "h": 6 }, "layer": "overlay", "page": "launcher" }
  ],
  "pages": {
    "clock": { "grid": { "cols": 10, "rows": 4 }, "widgets": [
      { "module": "vtnc.clock", "cell": { "x": 0, "y": 0, "w": 6, "h": 2 } },
      { "module": "vtnc.square", "cell": { "x": 6, "y": 0, "w": 2, "h": 2 } }
    ] },
    "launcher": { "grid": { "cols": 10, "rows": 6 }, "widgets": [] }
  },
  "hyprland": {
    "enabled": true,
    "keybinds": [
      { "key": "SUPER + Return", "commands": ["kitty"], "enabled": true, "description": "terminal" },
      { "key": "SUPER + D", "commands": ["vtnc page launcher call bar"], "enabled": true, "description": "launcher" },
      { "key": "SUPER + L", "commands": ["vtnc page lock call bar"], "enabled": false, "description": "lock screen" }
    ]
  }
}
EOF

rm -f "$out"
log=$(VTNC_CONFIG_DIR="$tmp_config_dir" VTNC_RENDER_OUT="$out" VTNC_RENDER_PAGE="$page" timeout 30 env QT_QPA_PLATFORM=wayland qs -p "$harness" -n 2>&1)
status=$?

if [[ $status -eq 124 ]]; then
    echo "FAIL: the render timed out — grabToImage never called back."
    echo "$log"
    exit 1
fi

if [[ ! -s "$out" ]]; then
    echo "FAIL: no image produced (qs exited $status)."
    echo "$log"
    exit 1
fi

[[ -n "$log" ]] && echo "$log"
echo "OK: rendered to $out — look at it."
exit 0
