#!/usr/bin/env bash
# Camada 3 da 0.509, critérios 4 e 5: trocar o style de um widget e ver a
# shell viva acompanhar.
#
# O que só se mede aqui, e não em node: que a shell RESOLVE o style pelo
# registro em vez de só repetir o que está no config.json. Uma instância sem
# `style` veste o padrão declarado no meta do type, e é o padrão que o
# `island get` devolve — se o registro não estivesse sendo lido de verdade
# dentro do QML, este campo viria vazio.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cfg=$(mktemp -d); env_f=$(mktemp)
real_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
fail=0

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null
    "$here/tools/headless/nested.sh" stop "$env_f"
    rm -rf "$cfg" "$env_f"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then echo "OK: $desc"
    else echo "FAIL: $desc — esperado [$expected], obtido [$got]"; fail=1; fi
}

# Duas islands na mesma page de novo: trocar o style é mexer na page, e a
# page é dona das instâncias (6.1), então as duas têm de mudar juntas.
cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true },
      "offset": {"x":0,"y":0}, "size": {"w":40,"h":4}, "gap": 0,
      "layer": "top", "page": "shared" },
    { "name": "dock", "anchor": { "bottom": true, "left": true },
      "offset": {"x":0,"y":0}, "size": {"w":20,"h":4}, "gap": 0,
      "layer": "top", "page": "shared" }
  ],
  "pages": {
    "shared": { "grid": {"cols":10,"rows":4},
      "widgets": [ { "type": "vtnc.clock", "cell": {"x":0,"y":0,"w":6,"h":2} } ] } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f" || exit 1
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "style-switch.sh: RECUSANDO — instância aninhada não comprovada" >&2
    exit 1
fi

export VTNC_CONFIG_DIR="$cfg"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

v() { "$here/cli/vtnc" "$@"; }
# "type:style" de cada widget, como a SHELL o vê — não como o config.json o
# escreveu.
seen() {
    v island "$1" get | python3 -c '
import json, sys
print(" ".join(w["type"] + ":" + str(w["style"]) for w in json.load(sys.stdin).get("widgets", [])))'
}

# --------------------------------------- critério 5: o padrão vem do registro
check "sem style na config, a shell mostra o padrão declarado no meta do type" \
    "$(seen bar)" "vtnc.clock:digital"
check "e a outra island na mesma page mostra o mesmo (6.1)" \
    "$(seen dock)" "vtnc.clock:digital"

# --------------------------------------- critério 4: trocar o style
v page shared set widgets \
    '[{"type":"vtnc.clock","style":"compact","cell":{"x":0,"y":0,"w":6,"h":2}}]' >/dev/null
sleep 0.6
check "trocar o style do widget chega na shell viva (critério 4/5)" \
    "$(seen bar)" "vtnc.clock:compact"
check "e chega nas DUAS islands que vestem a page, ao vivo (6.1)" \
    "$(seen dock)" "vtnc.clock:compact"

# --------------------------------------- um style que não existe
# Decisão nenhuma cobre isto, é defesa: a config é um arquivo de texto que o
# usuário pode editar à mão, e um nome errado não pode apagar o widget da
# tela. O registro cai no padrão do type.
v page shared set widgets \
    '[{"type":"vtnc.clock","style":"nao-existe","cell":{"x":0,"y":0,"w":6,"h":2}}]' >/dev/null
sleep 0.6
check "um style inexistente não derruba o widget: a shell ainda o desenha" \
    "$(v island bar get | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("widgets", [])))')" "1"

# --------------------------------------- voltar ao style de origem
v page shared set widgets \
    '[{"type":"vtnc.clock","style":"digital","cell":{"x":0,"y":0,"w":6,"h":2}}]' >/dev/null
sleep 0.6
check "voltar ao style anterior funciona igual" "$(seen bar)" "vtnc.clock:digital"

# --------------------------------------- dois widgets, styles diferentes
v page shared set widgets '[
  {"type":"vtnc.clock","style":"digital","cell":{"x":0,"y":0,"w":6,"h":2}},
  {"type":"vtnc.clock","style":"compact","cell":{"x":6,"y":0,"w":4,"h":2}},
  {"type":"vtnc.square","cell":{"x":0,"y":2,"w":2,"h":2}}]' >/dev/null
sleep 0.6
check "cada instância veste o seu próprio style, e o square cai no padrão dele" \
    "$(seen bar)" "vtnc.clock:digital vtnc.clock:compact vtnc.square:default"

exit "$fail"
