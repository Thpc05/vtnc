#!/usr/bin/env bash
# Layer 4: visual. Renders a page to a PNG and leaves it for a human to look
# at — decision 17.2 is explicit that this layer is eyeballed, not a pixel
# comparison.
#
# It needs a real compositor: under QT_QPA_PLATFORM=offscreen grabToImage
# never calls its callback back, with any combination of QT_QUICK_BACKEND and
# QSG_RENDER_LOOP. So this starts the nested test session itself, unless the
# caller already put us inside one (NESTED_PID set).

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="${1:-$here/render.png}"
own_nest=""

cleanup() {
    if [[ -n "$own_nest" ]]; then
        "$root/tools/headless/nested.sh" stop "$own_nest" || true
        rm -f "$own_nest"
    fi
}
trap cleanup EXIT

if [[ -z "${NESTED_PID:-}" ]]; then
    own_nest=$(mktemp)
    if ! "$root/tools/headless/nested.sh" start "$own_nest"; then
        echo "FAIL: the nested test compositor did not come up."
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$own_nest"
fi

rm -f "$out"
log=$(timeout 30 env QT_QPA_PLATFORM=wayland qml6 "$here/render.qml" -- "$out" 2>&1)
status=$?

if [[ $status -eq 124 ]]; then
    echo "FAIL: the render timed out — grabToImage never called back."
    echo "$log"
    exit 1
fi

if [[ ! -s "$out" ]]; then
    echo "FAIL: no image produced (qml6 exited $status)."
    echo "$log"
    exit 1
fi

[[ -n "$log" ]] && echo "$log"
echo "OK: rendered to $out — look at it."
exit 0
