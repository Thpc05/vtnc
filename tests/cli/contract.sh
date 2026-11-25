#!/usr/bin/env bash
# Layer 3: the CLI's JSON contract, against a live shell — this is also the
# acceptance test for 0.51's six criteria. Needs the nested test compositor
# (tools/headless/nested.sh) since `call`/`get`/`list` go over IPC to a
# running shell.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
nested_env=$(mktemp)
fail=0

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null || true
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
  "monitors": { "HEADLESS-2": { "factor": 1.25 } },
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 40, "h": 4 }, "layer": "top", "page": "clock" },
    { "name": "dock", "anchor": { "bottom": true, "left": true }, "offset": { "x": 2, "y": 2 }, "size": { "w": 20, "h": 6 }, "layer": "top", "page": "launcher" }
  ],
  "pages": {
    "clock": { "grid": { "cols": 10, "rows": 4 }, "widgets": [ { "module": "vtnc.square", "face": "default", "text": "clock", "cell": { "x": 0, "y": 0, "w": 6, "h": 4 } } ] },
    "launcher": { "grid": { "cols": 10, "rows": 6 }, "widgets": [ { "module": "vtnc.square", "face": "default", "text": "launcher", "cell": { "x": 0, "y": 0, "w": 20, "h": 6 } } ] },
    "dashboard": { "grid": { "cols": 10, "rows": 4 }, "widgets": [ { "module": "vtnc.clock", "face": "digital", "cell": { "x": 0, "y": 0, "w": 6, "h": 4 } } ] },
    "dashboard-compact": { "grid": { "cols": 10, "rows": 6 }, "widgets": [ { "module": "vtnc.clock", "face": "compact", "cell": { "x": 0, "y": 0, "w": 4, "h": 2 } } ] }
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

# Criterion 1: two islands, from config only, with different anchors.
list_json=$("$here/cli/vtnc" island list)
names=$(echo "$list_json" | python3 -c 'import json,sys; print(" ".join(i["name"] for i in json.load(sys.stdin)))')
check "two islands listed" "$names" "bar dock"

# Criterion 3: list reports position (anchor+offset), size in cells, layer.
has_fields=$(echo "$list_json" | python3 -c 'import json,sys; i=json.load(sys.stdin)[0]; print("anchor" in i and "size" in i and "layer" in i)')
check "list reports anchor/size/layer" "$has_fields" "True"

# Criterion 2: call switches the page live, get shows it.
# 0.506 moved the trigger to the page (decision 1b.5): `island <name> call`
# no longer exists, it's `page <name> call <island>` now.
"$here/cli/vtnc" page launcher call bar >/dev/null
got_page=$(echo "$("$here/cli/vtnc" island bar get)" | python3 -c 'import json,sys; print(json.load(sys.stdin)["page"])')
check "call switches page live" "$got_page" "launcher"

# 0.502 criterion 5: set refuses an unknown key or a value pointing at
# something that doesn't exist, and config.json stays untouched.
config_before=$(cat "$tmp_config_dir/config.json")
if "$here/cli/vtnc" island bar set page no-such-page >/dev/null 2>"$tmp_config_dir/set.err"; then
    check "set to a nonexistent page is refused" "accepted" "refused"
else
    check "set to a nonexistent page is refused" "refused" "refused"
fi
check "set error mentions the page" "$(grep -c 'no such page' "$tmp_config_dir/set.err")" "1"
config_after=$(cat "$tmp_config_dir/config.json")
check "config.json untouched after a refused set" "$([[ "$config_before" == "$config_after" ]] && echo same)" "same"

if "$here/cli/vtnc" island bar set banana 7 >/dev/null 2>"$tmp_config_dir/set2.err"; then
    check "set with an unknown key is refused" "accepted" "refused"
else
    check "set with an unknown key is refused" "refused" "refused"
fi
check "unknown-key error mentions it" "$(grep -c 'unknown key' "$tmp_config_dir/set2.err")" "1"

# 0.502 criterion 5: vtnc help lists all seven top-level namespaces.
help_out=$("$here/cli/vtnc" help)
missing=0
for ns in island page widget service monitor preset theme; do
    echo "$help_out" | grep -q "$ns" || missing=1
done
check "help lists all seven namespaces" "$missing" "0"

# 0.502 criterion 1/2/3: the clock service is off until a visible clock
# widget needs it, and two islands showing it share one instance.
check "clock service is off before any clock widget is visible" \
    "$("$here/cli/vtnc" service list | python3 -c 'import json,sys; s=[x for x in json.load(sys.stdin) if x["name"]=="clock"][0]; print(s["running"], s["holders"])')" \
    "False 0"

"$here/cli/vtnc" page dashboard call bar >/dev/null
"$here/cli/vtnc" page dashboard-compact call dock >/dev/null
sleep 0.3
# Not screen_count * 2 any more: 0.506 (decision 1e.3) means a called page
# reaches only the focused monitor's mirror, the others keep wearing idle
# (clock/launcher, neither of which uses the clock widget) — so each island
# contributes exactly one holder, regardless of how many screens it mirrors
# across.
check "clock turns on and is shared by two islands (two different faces)" \
    "$("$here/cli/vtnc" service list | python3 -c 'import json,sys; s=[x for x in json.load(sys.stdin) if x["name"]=="clock"][0]; print(s["running"], s["holders"])')" \
    "True 2"

"$here/cli/vtnc" island bar end >/dev/null
"$here/cli/vtnc" island dock end >/dev/null
sleep 0.3
check "clock turns back off once the last clock widget leaves" \
    "$("$here/cli/vtnc" service list | python3 -c 'import json,sys; s=[x for x in json.load(sys.stdin) if x["name"]=="clock"][0]; print(s["running"], s["holders"])')" \
    "False 0"

# Criterion 4: set survives a restart, call doesn't.
"$here/cli/vtnc" island bar set page dashboard >/dev/null
kill "$QS_PID"
wait "$QS_PID" 2>/dev/null || true
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$tmp_config_dir/qs2.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 50); do
    "$here/cli/vtnc" island list >/dev/null 2>&1 && break
    sleep 0.1
done
after_restart=$("$here/cli/vtnc" island bar get)
idle_page=$(echo "$after_restart" | python3 -c 'import json,sys; print(json.load(sys.stdin)["idlePage"])')
called_page=$(echo "$after_restart" | python3 -c 'import json,sys; print(json.load(sys.stdin)["calledPage"])')
check "set survived the restart" "$idle_page" "dashboard"
check "call did not survive the restart" "$called_page" ""

# Criterion 5: the monitor factor changes px size, not the cell layout —
# dock is 20x6 cells on both outputs; HEADLESS-2's factor (1.25) must scale
# it to exactly 1.25x the pixels HEADLESS-1 gets.
sizes=$(hyprctl layers -j | python3 -c '
import json, sys
layers = json.load(sys.stdin)
sizes = {}
for mon, data in layers.items():
    for level in data.get("levels", {}).values():
        for l in level:
            if l["namespace"] == "vtnc-island-dock":
                sizes[mon] = (l["w"], l["h"])
print(sizes.get("HEADLESS-1"), sizes.get("HEADLESS-2"))
')
check "dock scales 1.25x from HEADLESS-1 to HEADLESS-2" "$sizes" "(160, 48) (200, 60)"

# 0.503 criterion 1: Settings is a Hyprland window (hyprctl clients), not a
# layer-shell surface (hyprctl layers) — unlike every island.
has_settings_client=$(hyprctl clients -j | python3 -c 'import json,sys; print(any(c["title"]=="vtnc Settings" for c in json.load(sys.stdin)))')
check "Settings is listed in hyprctl clients" "$has_settings_client" "True"

has_settings_layer=$(hyprctl layers -j | python3 -c '
import json, sys
layers = json.load(sys.stdin)
found = False
for data in layers.values():
    for level in data.get("levels", {}).values():
        for l in level:
            if "vtnc Settings" in l.get("namespace", ""):
                found = True
print(found)
')
check "Settings is not listed in hyprctl layers" "$has_settings_layer" "False"

exit $fail
