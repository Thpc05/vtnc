#!/usr/bin/env bash
# Starts the default test compositor: a Hyprland instance nested inside the
# caller's own Hyprland session (see tools/README.md for why this is the
# default and when to escalate to Theo's real screen instead).
#
# Usage:
#   tools/headless/nested.sh start <env-file>   # launches it, writes vars to <env-file>
#   tools/headless/nested.sh stop  <env-file>   # kills it by the pid recorded there
#
# After `start`, `source <env-file>` to get WAYLAND_DISPLAY and
# HYPRLAND_INSTANCE_SIGNATURE pointed at the nested instance, plus NESTED_PID.
# Two virtual outputs are created to match Theo's real hardware: a FullHD
# laptop panel and a QuadHD monitor.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"
env_file="${2:-}"

if [[ -z "$cmd" || -z "$env_file" ]]; then
    echo "usage: $0 {start|stop} <env-file>" >&2
    exit 1
fi

if [[ "$cmd" == "stop" ]]; then
    if [[ -f "$env_file" ]]; then
        # shellcheck disable=SC1090
        source "$env_file"
        if [[ -n "${NESTED_PID:-}" ]]; then
            kill "$NESTED_PID" 2>/dev/null || true
        fi
        rm -f "$env_file"
    fi
    exit 0
fi

if [[ "$cmd" != "start" ]]; then
    echo "usage: $0 {start|stop} <env-file>" >&2
    exit 1
fi

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "nested.sh: no WAYLAND_DISPLAY in the environment — run this from inside a" >&2
    echo "real Hyprland session, don't strip the environment (no env -i)." >&2
    exit 1
fi

runtime_dir="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR must be set}"
before=$(ls "$runtime_dir/hypr" 2>/dev/null || true)

# Preserves the whole environment (crucially WAYLAND_DISPLAY) so Aquamarine's
# nested-Wayland backend finds the host compositor as its allocator.
Hyprland --config "$here/hyprland.lua" >"$runtime_dir/vtnc-nested-hyprland.log" 2>&1 &
nested_pid=$!

sig=""
for _ in $(seq 1 50); do
    after=$(ls "$runtime_dir/hypr" 2>/dev/null || true)
    sig=$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort) | head -1)
    [[ -n "$sig" ]] && [[ -S "$runtime_dir/hypr/$sig/.socket.sock" ]] && break
    sleep 0.1
done

if [[ -z "$sig" ]]; then
    echo "nested.sh: nested Hyprland never came up, see $runtime_dir/vtnc-nested-hyprland.log" >&2
    kill "$nested_pid" 2>/dev/null || true
    exit 1
fi

nested_wayland=$(hyprctl instances -j \
    | python3 -c "import json,sys; print(next(i['wl_socket'] for i in json.load(sys.stdin) if i['instance'] == '$sig'))" 2>/dev/null || true)

if [[ -z "$nested_wayland" ]]; then
    echo "nested.sh: could not read the nested instance's wl_socket" >&2
    kill "$nested_pid" 2>/dev/null || true
    exit 1
fi

# Two virtual outputs; hyprland.lua's monitor rules give the first HEADLESS-1
# (FullHD) and the second HEADLESS-2 (QuadHD), matching Theo's hardware.
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl output create headless >/dev/null
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl output create headless >/dev/null
sleep 0.2
out1=HEADLESS-1
out2=HEADLESS-2

cat >"$env_file" <<EOF
export WAYLAND_DISPLAY=$nested_wayland
export HYPRLAND_INSTANCE_SIGNATURE=$sig
export NESTED_PID=$nested_pid
export NESTED_OUTPUT_FULLHD=$out1
export NESTED_OUTPUT_QUADHD=$out2
EOF
