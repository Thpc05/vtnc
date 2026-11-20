#!/usr/bin/env bash
# Layer 4: visual. Renders a page to a PNG and leaves it for a human to look
# at — decision 17.2 is explicit that this layer is eyeballed, not a pixel
# comparison. No compositor needed (QT_QPA_PLATFORM=offscreen).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-$here/render.png}"

timeout 15 env QT_QPA_PLATFORM=offscreen qml6 "$here/render.qml" -- "$out"

if [[ -s "$out" ]]; then
    echo "OK: rendered to $out — look at it."
    exit 0
fi

echo "FAIL: no image produced."
exit 1
