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
log="$runtime_dir/vtnc-nested-hyprland.log"

# Which instances exist before we start, so we can tell ours apart.
known_instances() {
    hyprctl instances -j 2>/dev/null \
        | python3 -c 'import json,sys; print("\n".join(i["instance"] for i in json.load(sys.stdin)))' \
        2>/dev/null || true
}

# One launch attempt. Echoes "<signature> <wl_socket> <pid>" on success.
# Startup is not entirely reliable: roughly one attempt in three dies early
# with "could not connect to wayland server" and never registers an
# instance, so the caller retries.
attempt() {
    local before after sig pid line
    before=$(known_instances | sort)

    # Preserves the whole environment (crucially WAYLAND_DISPLAY) so
    # Aquamarine's nested-Wayland backend finds the host compositor as its
    # allocator. Hyprland first tries to name its own socket after
    # WAYLAND_DISPLAY, fails to lock the host's, and falls through to the
    # next free one — the "unable to lock lockfile" line in the log is
    # expected and harmless.
    Hyprland --config "$here/hyprland.lua" >"$log" 2>&1 &
    pid=$!

    # Wait for the instance to register: hyprctl only lists it once it has
    # written its lock file, which is exactly when it has a usable socket.
    for _ in $(seq 1 100); do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 1 # died during startup
        fi
        after=$(known_instances | sort)
        sig=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
        if [[ -n "$sig" ]]; then
            line=$(hyprctl instances -j \
                | python3 -c "import json,sys; print(next(i['wl_socket'] for i in json.load(sys.stdin) if i['instance'] == '$sig'))" \
                2>/dev/null || true)
            if [[ -n "$line" ]]; then
                echo "$sig $line $pid"
                return 0
            fi
        fi
        sleep 0.1
    done

    kill "$pid" 2>/dev/null || true
    return 1
}

result=""
for try in 1 2 3; do
    if result=$(attempt); then
        break
    fi
    result=""
    echo "nested.sh: attempt $try did not come up, retrying" >&2
    sleep 1
done

if [[ -z "$result" ]]; then
    echo "nested.sh: nested Hyprland never came up after 3 attempts, see $log" >&2
    exit 1
fi

read -r sig nested_wayland nested_pid <<<"$result"

# Two virtual outputs; hyprland.lua's monitor rules give the first HEADLESS-1
# (FullHD) and the second HEADLESS-2 (QuadHD), matching Theo's hardware.
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl output create headless >/dev/null
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl output create headless >/dev/null

# Wait for both to actually exist rather than guessing at a sleep.
for _ in $(seq 1 50); do
    count=$(HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl monitors -j 2>/dev/null \
        | python3 -c 'import json,sys; print(sum(1 for m in json.load(sys.stdin) if m["name"].startswith("HEADLESS-")))' \
        2>/dev/null || echo 0)
    [[ "$count" -ge 2 ]] && break
    sleep 0.1
done

cat >"$env_file" <<EOF
export WAYLAND_DISPLAY=$nested_wayland
export HYPRLAND_INSTANCE_SIGNATURE=$sig
export NESTED_PID=$nested_pid
export NESTED_OUTPUT_FULLHD=HEADLESS-1
export NESTED_OUTPUT_QUADHD=HEADLESS-2
EOF
