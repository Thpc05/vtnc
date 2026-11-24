#!/usr/bin/env bash
# Camada 3 da 0.508, critérios 1 a 4: o editor de Pages contra uma shell viva
# no compositor aninhado.
#
# Duas coisas se medem aqui que não dá para medir em node: que a shell
# enxerga a mudança (a decisão 6.1, duas islands na mesma page mudando
# juntas, lida pelo `widgetCount` que o `island get` devolve) e que o estado
# empty da 14.3 chega até o compositor — a bolinha reserva 2 células, não as
# quarenta da island cheia, e isso aparece no `reserved` do `monitors -j`.
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

# Duas islands vestindo A MESMA page: é esse o par que prova a 6.1. A `bar`
# fica no topo com 4 células de altura, que é o que a reserva vai medir.
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
    "shared": { "grid": {"cols":10,"rows":4}, "widgets": [] } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f" || exit 1
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "pages-editor.sh: RECUSANDO — instância aninhada não comprovada" >&2
    exit 1
fi

export VTNC_CONFIG_DIR="$cfg"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

v() { "$here/cli/vtnc" "$@"; }
field() { python3 -c "import json,sys; print(json.load(sys.stdin).get('$1'))"; }
# O `reserved` do monitor é [esq, topo, dir, baixo]; a `bar` ancora no topo.
reserved_top() {
    hyprctl monitors -j | python3 -c '
import json, sys
m = [x for x in json.load(sys.stdin) if x["name"] == "HEADLESS-1"][0]
print(m["reserved"][1])'
}

# ------------------------------------------------- critério 1: criar e listar
pages() { v page list | python3 -c 'import json,sys; print(" ".join(sorted(p["name"] for p in json.load(sys.stdin))))'; }
check "a page nasce pela CLI e a shell passa a listá-la (critério 1)" \
    "$(v page dash create >/dev/null; sleep 0.6; pages)" "dash shared"

# ------------------------------------------------- critério 2: grade e widgets
v page dash set grid '{"cols":12,"rows":6}' >/dev/null
v page dash set widgets '[{"type":"vtnc.clock","cell":{"x":0,"y":0,"w":6,"h":2}}]' >/dev/null
sleep 0.6
check "a grade da page muda (critério 2)" \
    "$(v page dash get | python3 -c 'import json,sys; g=json.load(sys.stdin)["grid"]; print("%sx%s" % (g["cols"], g["rows"]))')" "12x6"
check "o widget entra na page com a célula pedida (critério 2)" \
    "$(v page dash get | python3 -c 'import json,sys; w=json.load(sys.stdin)["widgets"][0]; print("%s %s %s" % (w["type"], w["cell"]["w"], w["cell"]["h"]))')" "vtnc.clock 6 2"
# Uma célula sem tamanho é recusada antes de encostar no config.json.
bad=$(v page dash set widgets '[{"type":"vtnc.clock","cell":{"x":0,"y":0,"w":0,"h":2}}]' 2>&1 >/dev/null; true)
check "uma célula inválida é recusada com explicação (critério 2)" \
    "$(echo "$bad" | grep -qi 'cell' && echo explica)" "explica"

# ------------------------------------------------- critério 3: a page é compartilhada
check "as duas islands na mesma page começam sem widget (critério 3)" \
    "$(v island bar get | field widgetCount)/$(v island dock get | field widgetCount)" "0/0"
v page shared set widgets '[{"type":"vtnc.clock","cell":{"x":0,"y":0,"w":6,"h":2}},
                            {"type":"vtnc.square","cell":{"x":6,"y":0,"w":2,"h":2}}]' >/dev/null
sleep 0.8
check "mexer na page muda as DUAS islands que a usam, ao vivo (critério 3 / 6.1)" \
    "$(v island bar get | field widgetCount)/$(v island dock get | field widgetCount)" "2/2"

# ------------------------------------------------- critério 4: o estado empty
check "antes de apagar, a reserva é a island cheia: 4 células de 8 px" "$(reserved_top)" "32"
check "e nenhuma das duas está vazia" \
    "$(v island bar get | field empty)/$(v island dock get | field empty)" "False/False"

orphans=$(v page shared delete | python3 -c 'import json,sys; print(" ".join(sorted(json.load(sys.stdin)["nowEmpty"])))')
check "apagar a page diz quais islands ficaram sem ela" "$orphans" "bar dock"
sleep 1
check "as duas islands caem no estado empty em vez de sumir (critério 4 / 14.3)" \
    "$(v island bar get | field empty)/$(v island dock get | field empty)" "True/True"
check "e a bolinha reserva 2 células, não as 4 da island cheia (critério 4)" \
    "$(reserved_top)" "16"

exit $fail
