#!/usr/bin/env bash
# Layer 3, 0.505's own acceptance criteria 1-4: autohide against a live
# shell in the nested test compositor. Needs real windows and hyprctl
# dispatch (liberated for test — AGENTS.md), since window/fullscreen modes
# read real Hyprland state and the hover reveal is proven by moving the
# real (nested) cursor, not simulated.
#
# Three islands, one per mode:
#   bar      — anchor top+left+right, autohide always. Hidden from the
#              moment the shell starts (criterion 1), revealed by hover at
#              the top edge (criterion 2) or by a call (criterion 4).
#   winhide  — anchor left (a lone edge, offset far enough from it that it
#              gets the shrink animation, not slide — exercises both
#              animation paths across this fixture), autohide window:
#              visible on an empty workspace, hides once any window exists.
#   fshide   — anchor bottom, autohide fullscreen: visible unless some
#              window on the workspace is fullscreen.
#
# All three reserve on a different edge, so hyprctl monitors -j's `reserved`
# ([left, top, right, bottom]) tells them apart without ambiguity.
#
# vtnc's own Settings window opens with the shell (decision 1d.6) and is a
# real Hyprland window — left where it lands, window-mode would never see
# an "empty" workspace. It's moved out of the way first, same idea as
# AGENTS.md's "go to an empty workspace, do what you need, come back".
#
# Pegadinha found here: the real kitty on this machine starts already
# fullscreen (Theo's own kitty config, nothing to do with vtnc) — this
# script doesn't assume which way the first `hyprctl dispatch fullscreen 0`
# flips it, it polls hyprctl workspaces -j's own `hasfullscreen` and
# re-dispatches until it's actually in the state the next check needs.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
nested_env=$(mktemp)
fail=0

# Safety net after a real session got disrupted once while this was being
# written: every Hyprland command below goes through nhyprctl/nkitty, which
# re-assert HYPRLAND_INSTANCE_SIGNATURE/WAYLAND_DISPLAY explicitly instead
# of trusting a `source`d export to stay in scope for the rest of the
# script — if anything upstream ever clobbers or loses that env, a plain
# `hyprctl`/`kitty` call here would silently fall back to whatever
# environment the shell actually has, which must never be the real session.
# The real session's own signature is captured first so a close/kill can be
# refused outright if nested_sig ever turns out to equal it.
real_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
nested_sig=""
nested_wl=""

nhyprctl() {
    HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" hyprctl "$@"
}

nkitty() {
    HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" WAYLAND_DISPLAY="$nested_wl" kitty >/dev/null 2>&1 &
}

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null || true
    if [[ -n "$nested_sig" ]]; then
        nhyprctl dispatch closewindow "class:kitty" >/dev/null 2>&1 || true
    fi
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
  "autohide": { "enabled": false, "mode": "always", "distance": 2, "fade": 150, "slideSpeed": 150, "shrinkSize": 1 },
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 40, "h": 4 }, "gap": 0, "layer": "top", "page": "idle", "autohide": true, "autohideMode": "always" },
    { "name": "winhide", "anchor": { "left": true }, "offset": { "x": 10, "y": 0 }, "size": { "w": 10, "h": 20 }, "gap": 0, "layer": "top", "page": "idle2", "autohide": true, "autohideMode": "window" },
    { "name": "fshide", "anchor": { "bottom": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 10, "h": 4 }, "gap": 0, "layer": "top", "page": "idle3", "autohide": true, "autohideMode": "fullscreen" }
  ],
  "pages": {
    "idle": { "grid": { "cols": 10, "rows": 4 }, "widgets": [ { "type": "vtnc.square", "style": "default", "text": "idle", "cell": { "x": 0, "y": 0, "w": 6, "h": 4 } } ] },
    "idle2": { "grid": { "cols": 10, "rows": 20 }, "widgets": [] },
    "idle3": { "grid": { "cols": 10, "rows": 4 }, "widgets": [] },
    "barcalled": { "grid": { "cols": 10, "rows": 4 }, "widgets": [] }
  }
}
EOF

"$here/tools/headless/nested.sh" start "$nested_env"
# shellcheck disable=SC1090
source "$nested_env"
nested_sig="$HYPRLAND_INSTANCE_SIGNATURE"
nested_wl="$WAYLAND_DISPLAY"

if [[ -z "$nested_sig" ]] || [[ -n "$real_sig" && "$nested_sig" == "$real_sig" ]]; then
    echo "autohide.sh: refusing to continue — nested_sig is empty or equals the real session's own signature" >&2
    exit 1
fi

export VTNC_CONFIG_DIR="$tmp_config_dir"
HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" WAYLAND_DISPLAY="$nested_wl" \
    QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$tmp_config_dir/qs.log" 2>&1 &
QS_PID=$!

for _ in $(seq 1 50); do
    "$here/cli/vtnc" island list >/dev/null 2>&1 && break
    sleep 0.1
done

# Settings opens with the shell, on whichever workspace is focused at that
# moment — move it well out of the way, then park HEADLESS-1 on a
# workspace of its own, so "a window exists" starts out false for real.
nhyprctl dispatch movetoworkspacesilent "99,title:^vtnc Settings$" >/dev/null
nhyprctl dispatch focusmonitor HEADLESS-1 >/dev/null
nhyprctl dispatch workspace 2 >/dev/null
sleep 0.6 # past the 150ms settle + HoverCursor's first poll

reserved_all() {
    nhyprctl monitors -j | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    if m["name"] == "HEADLESS-1":
        print(m["reserved"])  # [left, top, right, bottom]
'
}

monitor_geometry() {
    nhyprctl monitors -j | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    if m["name"] == "HEADLESS-1":
        print(m["x"], m["y"], m["width"], m["height"])
'
}
read -r mon_x mon_y mon_w mon_h <<<"$(monitor_geometry)"

workspace2_has_fullscreen() {
    nhyprctl workspaces -j | python3 -c '
import json, sys
for w in json.load(sys.stdin):
    if w["name"] == "2":
        print(w["hasfullscreen"])
'
}

# Toggles fullscreen on workspace 2's active window until hasfullscreen
# matches what's wanted — doesn't assume which way a single dispatch flips
# it (see the kitty note above).
ensure_fullscreen() {
    local want="$1"
    for _ in $(seq 1 20); do
        [[ "$(workspace2_has_fullscreen)" == "$want" ]] && return 0
        nhyprctl dispatch fullscreen 0 >/dev/null
        sleep 0.2
    done
    return 1
}

# Criterion 1, part 1: bar has autohide=always from the moment the shell
# starts — nothing hovering it, nothing calling it — so it's already
# hidden: no reservation on top, even though winhide (left, 80px) and
# fshide (bottom, 32px) are both still visible (an empty workspace
# triggers neither window nor fullscreen mode).
check "bar starts autohidden on an empty workspace: no top reservation" "$(reserved_all)" "[80, 0, 0, 32]"

# Criterion 3 (window mode): a real window opens on this workspace, in the
# nested instance only (nkitty asserts the nested signature explicitly).
nkitty
for _ in $(seq 1 50); do
    nhyprctl clients -j 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if any("kitty" in c.get("class","").lower() for c in json.load(sys.stdin)) else 1)' && break
    sleep 0.1
done
ensure_fullscreen False # this kitty starts fullscreen already; get it out of the way first
sleep 0.6

check "opening a (non-fullscreen) window hides the window-mode island (left reservation drops)" "$(reserved_all)" "[0, 0, 0, 32]"

# Criterion 1, part 2: the real window actually grows into bar's own,
# never-reserved strip — it never sat under a phantom 32px top margin.
kitty_y=$(nhyprctl clients -j | python3 -c '
import json, sys
for c in json.load(sys.stdin):
    if "kitty" in c.get("class", "").lower():
        print(c["at"][1])
        break
')
check "the real window starts at y=0, not under bar's (never reserved) strip" "$kitty_y" "0"

# Criterion 3 (fullscreen mode): make that window fullscreen.
ensure_fullscreen True
sleep 0.6
check "a fullscreen window hides the fullscreen-mode island (bottom reservation drops)" "$(reserved_all)" "[0, 0, 0, 0]"

ensure_fullscreen False
sleep 0.6
check "leaving fullscreen brings the fullscreen-mode island back" "$(reserved_all)" "[0, 0, 0, 32]"

nhyprctl dispatch closewindow "class:kitty" >/dev/null 2>&1 || true
for _ in $(seq 1 50); do
    nhyprctl clients -j 2>/dev/null | python3 -c 'import json,sys; sys.exit(1 if any("kitty" in c.get("class","").lower() for c in json.load(sys.stdin)) else 0)' && break
    sleep 0.1
done
sleep 0.6
check "closing the window brings the window-mode island back too" "$(reserved_all)" "[80, 0, 0, 32]"

# Criterion 2: hover at bar's nearest border (the monitor's top edge)
# reveals it, and the reservation comes back immediately (not gated by the
# settle delay — only hiding is). Moving away hides it again.
hover_x=$((mon_x + mon_w / 2))
hover_y=$((mon_y + 2)) # well inside the default 2-cell/16px band
nhyprctl dispatch movecursor "$hover_x" "$hover_y" >/dev/null
sleep 0.4 # HoverCursor polls every 100ms
check "hovering bar's top edge reveals it (top reservation comes back)" "$(reserved_all)" "[80, 32, 0, 32]"

away_x=$((mon_x + mon_w / 2))
away_y=$((mon_y + mon_h / 2)) # screen center: outside every band and every island's own rect
nhyprctl dispatch movecursor "$away_x" "$away_y" >/dev/null
sleep 0.9 # poll + the 150ms settle delay, with margin
check "moving away hides bar again" "$(reserved_all)" "[80, 0, 0, 32]"

# Criterion 4: a call reveals a hidden island; calling the idle page back
# ends it (there's no separate "end call" verb yet — see island/Island.qml
# — so this reuses the one mechanism that already exists).
"$here/cli/vtnc" island bar call barcalled >/dev/null
sleep 0.3 # reveal is immediate, not settle-gated
check "a call reveals bar even with the mouse away (top reservation back)" "$(reserved_all)" "[80, 32, 0, 32]"

"$here/cli/vtnc" island bar call idle >/dev/null
sleep 0.9
check "calling the idle page back ends the call, and bar hides again" "$(reserved_all)" "[80, 0, 0, 32]"

exit $fail
