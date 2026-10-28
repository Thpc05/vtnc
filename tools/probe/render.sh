#!/bin/sh
# Renders a gallery QML offscreen, in dark and light, to PNGs. See README.md.
#
#   tools/probe/render.sh <gallery.qml> [out prefix]
#
# Env: VTNC (the shell, default ~/.config/quickshell/vtnc), PROBE_DIR (where the probes are built; default $XDG_RUNTIME_DIR/vtnc-probe or /tmp/vtnc-probe;
# must be outside the shell), PROBE_WIDGETS (Iwidgets for mkisland.py, space separated), plus the stubs'
# PROBE_ISLAND / PROBE_BATT / PROBE_ART / PROBE_PAUSED. Writes <out prefix>-dark.png and -light.png
# (default prefix: the gallery's name, next to it in PROBE_DIR).
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
# the live shell (the tools live on the dev branch, outside it)
VTNC=$(cd "${VTNC:-$HOME/.config/quickshell/vtnc}" && pwd)
ROOT=${PROBE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/vtnc-probe}

[ $# -ge 1 ] || { echo "usage: render.sh <gallery.qml> [out prefix]" >&2; exit 2; }
GALLERY=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
[ -f "$GALLERY" ] || { echo "no gallery: $GALLERY" >&2; exit 1; }
NAME=$(basename "$GALLERY" .qml)
PREFIX=${2:-$ROOT/$NAME}

# never build or run inside the shell's code: checked before anything is created (the path made absolute
# without creating it), and again on the real path once it exists
case "$ROOT" in /*) ;; *) ROOT=$(pwd)/$ROOT ;; esac
case "$ROOT/" in
"$VTNC"/*) echo "refused: PROBE_DIR $ROOT is inside the shell ($VTNC)" >&2; exit 1 ;;
esac
mkdir -p "$ROOT"
[ -d "$ROOT" ] || { echo "no PROBE_DIR: $ROOT" >&2; exit 1; }
ROOT=$(cd "$ROOT" && pwd -P)
case "$ROOT/" in
"$VTNC"/* | "$(cd "$VTNC" && pwd -P)"/*) echo "refused: PROBE_DIR $ROOT is inside the shell ($VTNC)" >&2; exit 1 ;;
esac

for m in dark light; do
    P=$ROOT/probe-$m
    python3 -I "$HERE/mkprobe.py" "$P" "$m" >/dev/null
    # shellcheck disable=SC2086
    python3 -I "$HERE/mkisland.py" "$P" ${PROBE_WIDGETS:-} >/dev/null
    [ -d "$P" ] && [ -f "$P/.vtnc-probe" ] || { echo "no probe dir: $P" >&2; exit 1; }
    cp "$GALLERY" "$P/$NAME.qml"
    rm -f "$PREFIX-$m.png"
    # shaders and MultiEffect masks render only on rhi + opengl (software ignores them, vulkan hangs)
    (cd "$P" && OUT="$PREFIX-$m.png" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl \
        timeout 25 qs -p "$NAME.qml" 2>&1 | grep -E "ERROR|qml\]|WARN.*scene" | grep -v "dropped" | head -12) || true
    if [ -f "$PREFIX-$m.png" ]; then echo "$PREFIX-$m.png"; else echo "no image for $m" >&2; fi
done
