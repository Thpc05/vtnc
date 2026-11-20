#!/usr/bin/env bash
# Layer 2: the whole QML compiles. Needs no compositor at all —
# QT_QPA_PLATFORM=offscreen takes it as far as it can go without a real
# Wayland connection (up to "no PanelWindow backend loaded", which is
# exactly the point where a real backend would be needed — everything
# before that, every import and type reference, has already resolved).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
trap 'rm -rf "$tmp_config_dir"' EXIT

out=$(VTNC_CONFIG_DIR="$tmp_config_dir" QT_QPA_PLATFORM=offscreen \
    timeout 8 qs -p "$here" -n 2>&1 || true)

echo "$out"

if echo "$out" | grep -q "No PanelWindow backend loaded"; then
    echo "OK: QML compiled, stopped only at the expected no-compositor point."
    exit 0
fi

if echo "$out" | grep -qiE "error|unavailable|not a type"; then
    echo "FAIL: QML did not compile cleanly."
    exit 1
fi

echo "FAIL: unexpected output, did not reach the expected stopping point."
exit 1
