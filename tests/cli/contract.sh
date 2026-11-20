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
    "clock": { "grid": { "cols": 10, "rows": 4 }, "widgets": [ { "type": "vtnc.square", "style": "default", "text": "clock", "cell": { "x": 0, "y": 0, "w": 6, "h": 4 } } ] },
    "launcher": { "grid": { "cols": 10, "rows": 6 }, "widgets": [ { "type": "vtnc.square", "style": "default", "text": "launcher", "cell": { "x": 0, "y": 0, "w": 20, "h": 6 } } ] }
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
"$here/cli/vtnc" island bar call launcher >/dev/null
got_page=$(echo "$("$here/cli/vtnc" island bar get)" | python3 -c 'import json,sys; print(json.load(sys.stdin)["page"])')
check "call switches page live" "$got_page" "launcher"

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

exit $fail
