#!/usr/bin/env bash
# Layer 3, 0.505: o modo window le o workspace em foco de CADA monitor, nao
# o unico workspace globalmente em foco (decisao autohide-window-por-monitor).
#
# Essa era a unica ambiguidade que sobrou da 0.505: a decisao dizia "o
# workspace em foco", no singular, e com varios monitores existem varios ao
# mesmo tempo. Medido no aninhado e repetido na tela real do Theo, com o
# mesmo resultado nos dois.
#
# O arranjo importa: a shell sobe num workspace descartavel, de modo que a
# janela da Settings fique la e nao conte como "existe janela" em nenhum dos
# workspaces que o teste usa — foi exatamente isso que embaralhou a primeira
# tomada na tela real.
set -uo pipefail
fail=0
here=/home/thpc/.config/quickshell/vtnc-dev
cfg=$(mktemp -d); env_f=$(mktemp)
real_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
nested_sig=""; nested_wl=""; nested_ok=0

cleanup() {
    [[ -n "${KITTY_PID:-}" ]] && kill "$KITTY_PID" 2>/dev/null
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null
    "$here/tools/headless/nested.sh" stop "$env_f"
    rm -rf "$cfg" "$env_f"
}
trap cleanup EXIT

cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "autohide": { "enabled": false, "mode": "always", "distance": 2, "fade": 150, "slideSpeed": 150, "shrinkSize": 1 },
  "islands": [
    { "name": "side", "anchor": { "left": true }, "offset": {"x":0,"y":0},
      "size": {"w":10,"h":20}, "gap": 0, "layer": "top", "page": "idle",
      "autohide": true, "autohideMode": "window" }
  ],
  "pages": { "idle": { "grid": {"cols":10,"rows":20}, "widgets": [] } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f"
# shellcheck disable=SC1090
source "$env_f"
nested_sig="$HYPRLAND_INSTANCE_SIGNATURE"; nested_wl="$WAYLAND_DISPLAY"
if [[ -z "$nested_sig" || -z "$nested_wl" || "$nested_sig" == "$real_sig" ]]; then
    echo "recusando: instancia aninhada nao comprovada" >&2; exit 1
fi
nested_ok=1

nh() { HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" hyprctl "$@"; }
nd() {
    local out; out="$(HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" hyprctl dispatch "$1" 2>&1)" || true
    [[ "$out" == "ok" ]] || { echo "dispatch [$1] falhou: $out" >&2; return 1; }
}

mede() {
    printf '%-52s' "$1"
    nh monitors -j | python3 -c '
import json, sys
out = []
for m in json.load(sys.stdin):
    ws = m.get("activeWorkspace", {}).get("name", "?")
    out.append("%s ws%s esq=%s" % (m["name"], ws, m["reserved"][0]))
print("  |  ".join(out))'
}

# A shell sobe num workspace descartavel: a Settings nasce la e nao vai
# contar como janela em nenhum dos workspaces que o teste usa.
nd 'hl.dsp.focus({ monitor = "HEADLESS-1" })'
nd 'hl.dsp.focus({ workspace = 99 })'

export VTNC_CONFIG_DIR="$cfg"
HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" WAYLAND_DISPLAY="$nested_wl" \
    QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

# Cada monitor num workspace vazio proprio.
nd 'hl.dsp.focus({ monitor = "HEADLESS-2" })'
nd 'hl.dsp.focus({ workspace = 3 })'
nd 'hl.dsp.focus({ monitor = "HEADLESS-1" })'
nd 'hl.dsp.focus({ workspace = 2 })'
sleep 1.5

echo
mede "dois workspaces vazios (esperado: visivel nos dois):"

# Uma janela em HEADLESS-1 apenas. O foco esta em HEADLESS-1, entao ela
# nasce no workspace 2 dele.
HYPRLAND_INSTANCE_SIGNATURE="$nested_sig" WAYLAND_DISPLAY="$nested_wl" kitty >/dev/null 2>&1 &
KITTY_PID=$!
for _ in $(seq 1 80); do
    nh clients -j | python3 -c "import json,sys; sys.exit(0 if any(c.get('pid')==$KITTY_PID for c in json.load(sys.stdin)) else 1)" && break
    sleep 0.2
done
sleep 1.5

echo
echo "janela aberta so em HEADLESS-1:"
nh clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c.get('pid') == $KITTY_PID:
        print('    kitty em', c.get('monitor'), 'workspace', c['workspace'].get('name'))"
mede "   e agora:"
check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then echo "OK: $desc"
    else echo "FAIL: $desc — expected [$expected], got [$got]"; fail=1; fi
}

esq() {
    nh monitors -j | python3 -c "
import json, sys
for m in json.load(sys.stdin):
    if m['name'] == '$1': print(m['reserved'][0])"
}

echo
nh monitors -j | python3 -c '
import json, sys
r = {m["name"]: m["reserved"][0] for m in json.load(sys.stdin)}
h1, h2 = r.get("HEADLESS-1"), r.get("HEADLESS-2")
if h1 == 0 and h2 == 0:
    print("    sumiu nos DOIS -> o modo window le o workspace em foco GLOBAL")
elif h1 == 0 and h2 and h2 > 0:
    print("    sumiu so em HEADLESS-1 -> o modo window le POR MONITOR")
else:
    print("    inconclusivo: HEADLESS-1 =", h1, " HEADLESS-2 =", h2)'

check "a janela esconde o espelho do monitor onde ela esta" "$(esq HEADLESS-1)" "0"
check "e NAO esconde o espelho do outro monitor" "$(esq HEADLESS-2)" "80"

exit $fail
