#!/usr/bin/env bash
# 0.507 criterion 1's click path for the consent toggle, modeled on
# settings-autohide-click-path.sh: finds the toggle's real MouseArea in the
# built Panel by its own label ("off", since the fixture config has no
# hyprland.enabled yet) and emits its clicked signal, then checks the write
# reached config.json's hyprland.enabled — and only that, nothing under
# ~/.config/hypr, since no shell (and so no core/HyprlandSync.qml) is
# running in this harness at all.
#
# Same Quickshell.shellDir constraint as the other tests/cli harnesses: runs
# from a disposable copy at vtnc-dev's root with the import rewritten. No
# compositor, no real windows, no hyprctl call anywhere in this path.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-keybinds-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./widgets/keybinds-editor#./widgets/keybinds-editor#' \
    "$here/tests/cli/settings-keybinds-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "autohide": { "enabled": false, "mode": "always", "distance": 2 },
  "hyprland": { "enabled": false, "keybinds": [] },
  "islands": [],
  "pages": {}
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

check "the consent toggle (labelled off) was found in the built Panel" \
    "$(echo "$log" | grep -c 'KEYBINDSCLICKPATH: clicking the off chip')" "1"

enabled_after=$(python3 -c 'import json; print(json.load(open("'"$tmp_config_dir"'/config.json"))["hyprland"]["enabled"])')
check "clicking the toggle turned hyprland.enabled on in config.json" "$enabled_after" "True"

check "nothing under a hypr folder was ever created by this harness" \
    "$(find "$tmp_config_dir" -iname 'hypr' | wc -l)" "0"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
