#!/usr/bin/env bash
# 0.503 acceptance criterion 4: Settings never writes configuration on its
# own — only `cli/vtnc` does. Drives the real vtnc.island-editor module
# (settings-write-boundary.qml) the way a click on it would, once with
# cli/vtnc executable and once without, and checks config.json either
# changed or stayed byte-for-byte the same.
#
# Needs no compositor: core/CliRunner.qml only needs Quickshell.shellDir,
# which `qs -p` resolves from the file it's given — so the harness has to
# run from vtnc-dev's own root (shellDir is "wherever this file lives",
# not "wherever cli/vtnc lives"). This script copies it there for the
# run and removes the copy afterward; the committed source stays in tests/.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-write-boundary-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    chmod +x "$here/cli/vtnc" 2>/dev/null || true
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

# Quickshell.shellDir is "wherever this file lives", so the import path
# has to become relative to vtnc-dev's root, not to tests/cli/.
sed 's#\.\./\.\./widgets/island-editor#./widgets/island-editor#' \
    "$here/tests/cli/settings-write-boundary.qml" >"$harness"

reset_config() {
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
}

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then
        echo "OK: $desc"
    else
        echo "FAIL: $desc — expected [$expected], got [$got]"
        fail=1
    fi
}

reset_config
VTNC_CONFIG_DIR="$tmp_config_dir" QT_QPA_PLATFORM=offscreen timeout 5 qs -p "$harness" -n >/dev/null 2>&1 || true
layer_after=$(python3 -c 'import json; print(json.load(open("'"$tmp_config_dir"'/config.json"))["islands"][0]["layer"])')
check "island-editor's setLayer reaches config.json through the real cli/vtnc" "$layer_after" "overlay"

reset_config
before=$(cat "$tmp_config_dir/config.json")
chmod -x "$here/cli/vtnc"
VTNC_CONFIG_DIR="$tmp_config_dir" QT_QPA_PLATFORM=offscreen timeout 5 qs -p "$harness" -n >/dev/null 2>&1 || true
chmod +x "$here/cli/vtnc"
after=$(cat "$tmp_config_dir/config.json")
check "with cli/vtnc non-executable, config.json is untouched" "$([[ "$before" == "$after" ]] && echo same)" "same"

exit $fail
