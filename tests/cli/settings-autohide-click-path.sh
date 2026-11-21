#!/usr/bin/env bash
# 0.505 criterion 5's click path for the autohide toggle, modeled on
# settings-click-path.sh/settings-gap-click-path.sh (see tests/README.md):
# finds the toggle's real MouseArea in the built Panel by its own label
# ("off", since the fixture island has no autohide override and the global
# default is off) and emits its clicked signal, then checks the whole chain
# reached config.json.
#
# Same Quickshell.shellDir constraint as the other tests/cli harnesses:
# runs from a disposable copy at vtnc-dev's root with the import rewritten.
# No compositor, no real windows — this is pure QML object-tree + signal
# emission under QT_QPA_PLATFORM=offscreen.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-autohide-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./widgets/island-editor#./widgets/island-editor#' \
    "$here/tests/cli/settings-autohide-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "autohide": { "enabled": false, "mode": "always", "distance": 2 },
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

check "the autohide toggle (labelled off) was found in the built Panel" \
    "$(echo "$log" | grep -c 'AUTOHIDECLICKPATH: clicking the off chip')" "1"

autohide_after=$(python3 -c 'import json; print(json.load(open("'"$tmp_config_dir"'/config.json"))["islands"][0]["autohide"])')
check "clicking the toggle turned the island's own autohide on in config.json" "$autohide_after" "True"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
