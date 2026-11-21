#!/usr/bin/env bash
# Coordinator-side reinforcement of 0.503's criteria 3 and 4: not "the
# type's functions reach config.json" (settings-write-boundary.sh already
# proves that), but "clicking the control calls the function". It emits the
# clicked signal of the real MouseArea inside the real Panel style, so the
# whole chain runs: MouseArea -> Chip.activated -> IslandEditor.setLayer ->
# CliRunner -> cli/vtnc -> config.json.
#
# Same constraint as settings-write-boundary.sh: Quickshell.shellDir is the
# directory of the file `qs -p` is given, and CliRunner builds the path to
# cli/vtnc from it, so the harness runs from a copy at vtnc-dev's root with
# its import rewritten. The committed source stays here.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./widgets/island-editor#./widgets/island-editor#' \
    "$here/tests/cli/settings-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 10, "h": 2 }, "layer": "top", "page": "x" }
  ],
  "pages": { "x": { "grid": { "cols": 1, "rows": 1 }, "widgets": [] } }
}
EOF

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then
        echo "OK: $desc"
    else
        echo "FAIL: $desc — expected [$expected], got [$got]"
        fail=1
    fi
}

log=$(VTNC_CONFIG_DIR="$tmp_config_dir" QT_QPA_PLATFORM=offscreen \
    timeout 10 qs -p "$harness" -n 2>&1 || true)

check "the overlay chip was found in the built Panel" \
    "$(echo "$log" | grep -c 'CLICKPATH: clicking the overlay chip')" "1"

layer_after=$(python3 -c 'import json; print(json.load(open("'"$tmp_config_dir"'/config.json"))["islands"][0]["layer"])')
check "clicking the chip changed the island's layer in config.json" "$layer_after" "overlay"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
