#!/usr/bin/env bash
# 0.504 criterion 5's click path, modeled on the coordinator's
# settings-click-path.sh (see tests/README.md): finds the gap stepper's
# real "+" MouseArea in the built Panel and emits its clicked signal, then
# checks the whole chain reached config.json.
#
# Same Quickshell.shellDir constraint as the other tests/cli harnesses:
# runs from a disposable copy at vtnc-dev's root with the import rewritten.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-gap-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./widgets/island-editor#./widgets/island-editor#' \
    "$here/tests/cli/settings-gap-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true }, "offset": { "x": 0, "y": 0 }, "size": { "w": 10, "h": 2 }, "gap": 1, "layer": "top", "page": "x" }
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

check "the gap stepper's + button was found in the built Panel" \
    "$(echo "$log" | grep -c 'GAPCLICKPATH: clicking the gap')" "1"

gap_after=$(python3 -c 'import json; print(json.load(open("'"$tmp_config_dir"'/config.json"))["islands"][0]["gap"])')
check "clicking the + button increased the island's gap in config.json" "$gap_after" "2"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
