#!/usr/bin/env bash
# Layer 4: visual. Renders a page to a PNG and leaves it for a human to look
# at — decision 17.2 is explicit that this layer is eyeballed, not a pixel
# comparison.
#
# It needs a real compositor: under QT_QPA_PLATFORM=offscreen grabToImage
# never calls its callback back, with any combination of QT_QUICK_BACKEND and
# QSG_RENDER_LOOP. So this starts the nested test session itself, unless the
# caller already put us inside one (NESTED_PID set).
#
# 0.503: runs via `qs -p` now, not plain qml6 — Page.qml started
# unconditionally importing widgets/island-editor (for its switch case),
# which needs core/Config.qml, a pragma Singleton that only resolves with
# the Quickshell runtime `qs` provides. `qs -p <file>` also only resolves
# qmldir imports under that file's own directory, so the harness runs from
# a disposable copy at vtnc-dev's root with its import rewritten — the
# versioned render.qml in tests/visual/ is untouched.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="${1:-$here/render.png}"
own_nest=""
harness="$root/.render-test.qml"

cleanup() {
    if [[ -n "$own_nest" ]]; then
        "$root/tools/headless/nested.sh" stop "$own_nest" || true
        rm -f "$own_nest"
    fi
    rm -f "$harness"
}
trap cleanup EXIT

sed 's#\.\./\.\./page#./page#' "$here/render.qml" >"$harness"

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
log=$(VTNC_RENDER_OUT="$out" timeout 30 env QT_QPA_PLATFORM=wayland qs -p "$harness" -n 2>&1)
status=$?

if [[ $status -eq 124 ]]; then
    echo "FAIL: the render timed out — grabToImage never called back."
    echo "$log"
    exit 1
fi

if [[ ! -s "$out" ]]; then
    echo "FAIL: no image produced (qs exited $status)."
    echo "$log"
    exit 1
fi

[[ -n "$log" ]] && echo "$log"
echo "OK: rendered to $out — look at it."
exit 0
