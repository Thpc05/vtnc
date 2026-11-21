#!/usr/bin/env bash
# Layer 3, 0.504's own acceptance criteria 1-4: the exclusive-zone
# reservation against a live shell in the nested test compositor. Needs
# real windows (hyprctl dispatch / opening kitty are liberated for test —
# AGENTS.md) because `hyprctl monitors -j`'s own `reserved` field is the
# exact measurement (decision: ask Hyprland, don't infer from a client
# window's size) — kitty is opened too, as a second, independent
# confirmation a human can repeat on the real screen.
#
# Fixture has four islands, one per corner of acceptance criterion 4:
#   bar    — anchored top+left+right (a full-width strip), idle page set.
#            The only one expected to reserve anything.
#   dock   — anchored bottom+left (a bare corner, not spanning either
#            axis): ambiguous to Hyprland even with an explicit exclusive
#            zone (measured in 0.504, see core/grid.mjs), reserves nothing.
#   float  — not anchored to any edge at all: reserves nothing (1d.5).
#   silent — anchored top, but with no idle page: reserves nothing (2d.4).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
nested_env=$(mktemp)
fail=0

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null || true
    [[ -n "${KITTY_PID:-}" ]] && kill "$KITTY_PID" 2>/dev/null || true
    "$here/tools/headless/nested.sh" stop "$nested_env" || true
    rm -rf "$tmp_config_dir" "$nested_env"
}
trap cleanup EXIT

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then
        echo "OK: $desc"
    else
        echo "FAIL: $desc — expected [$expected], got [$got]"
        fail=1
    fi
}

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 40, "h": 4 }, "gap": 0, "layer": "top", "page": "idle" },
    { "name": "dock", "anchor": { "bottom": true, "left": true }, "offset": { "x": 2, "y": 2 }, "size": { "w": 20, "h": 6 }, "gap": 3, "layer": "top", "page": "idle" },
    { "name": "float", "anchor": {}, "offset": { "x": 0, "y": 0 }, "size": { "w": 10, "h": 4 }, "gap": 5, "layer": "top", "page": "idle" },
    { "name": "silent", "anchor": { "top": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 10, "h": 4 }, "gap": 5, "layer": "top", "page": "" }
  ],
  "pages": {
    "idle": { "grid": { "cols": 10, "rows": 4 }, "widgets": [ { "type": "vtnc.square", "style": "default", "text": "idle", "cell": { "x": 0, "y": 0, "w": 6, "h": 4 } } ] },
    "big": { "grid": { "cols": 10, "rows": 20 }, "widgets": [ { "type": "vtnc.square", "style": "default", "text": "big", "cell": { "x": 0, "y": 0, "w": 6, "h": 20 } } ] }
  }
}
EOF

"$here/tools/headless/nested.sh" start "$nested_env"
# shellcheck disable=SC1090
source "$nested_env"

export VTNC_CONFIG_DIR="$tmp_config_dir"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$tmp_config_dir/qs.log" 2>&1 &
QS_PID=$!

for _ in $(seq 1 50); do
    "$here/cli/vtnc" island list >/dev/null 2>&1 && break
    sleep 0.1
done
sleep 0.5

reserved_top() {
    hyprctl monitors -j | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    if m["name"] == "HEADLESS-1":
        print(m["reserved"][1])  # [left, top, right, bottom]
'
}

# Criterion 1: bar (40x4 cells, base cell 8px, no gap) reserves exactly its
# own height on the top edge — 4 * 8 = 32px. dock/float/silent all have a
# gap configured too, so if any of them leaked a reservation this would be
# higher than 32.
check "bar alone reserves exactly its height in px (criterion 1)" "$(reserved_top)" "32"

# Criterion 4: island not anchored to a usable edge (float), without an
# idle page (silent), or anchored to a bare corner (dock) — all contribute
# zero, confirmed by the total staying at bar's own 32px.
check "dock (bare corner), float (no edge) and silent (no idle page) add nothing (criterion 4)" "$(reserved_top)" "32"

# Criterion 2: the gap adds exactly N cells in px, only on the anchored
# side. 3 cells * 8px = 24 more, landing on top (bar's edge) — nothing else
# changes. The sleep matters: islands.qml rebuilds its Variants repeater on
# any config change, so there's a brief window where the old and the new
# surface both exist and both contribute — reading too early once caught
# 32+56=88, a transient double-count, not a real bug.
"$here/cli/vtnc" island bar set gap 3 >/dev/null
sleep 0.5
check "gap of 3 cells adds exactly 24px to the reservation (criterion 2)" "$(reserved_top)" "56"
"$here/cli/vtnc" island bar set gap 0 >/dev/null
sleep 0.5
check "gap back to 0 returns the reservation to 32px" "$(reserved_top)" "32"

# Criterion 3: a call to a page that would make bar's content far taller
# than its own 4-cell height does not move the reservation — it's frozen to
# island.size (which a call never touches), not to whatever the page needs.
"$here/cli/vtnc" island bar call big >/dev/null
sleep 0.3
check "a call to a bigger page leaves the reservation untouched (criterion 3)" "$(reserved_top)" "32"
"$here/cli/vtnc" island bar call idle >/dev/null

# Second, independent confirmation with a real client window (liberated for
# test — AGENTS.md): a freshly opened kitty, tiled, must start below bar's
# reserved strip, not under it. Easy to repeat on the real screen: open a
# terminal and look at where it lands.
kitty >/dev/null 2>&1 &
KITTY_PID=$!
for _ in $(seq 1 50); do
    hyprctl clients -j 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if any("kitty" in c.get("class","").lower() for c in json.load(sys.stdin)) else 1)' && break
    sleep 0.1
done
kitty_y=$(hyprctl clients -j | python3 -c '
import json, sys
for c in json.load(sys.stdin):
    if "kitty" in c.get("class", "").lower():
        print(c["at"][1])
        break
')
check "a real kitty window tiles below bar's reserved strip, not under it" "$([[ "${kitty_y:-0}" -ge 32 ]] && echo yes)" "yes"

exit $fail
