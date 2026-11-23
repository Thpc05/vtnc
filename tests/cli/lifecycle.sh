#!/usr/bin/env bash
# Camada 3, critérios 1, 2, 3 e 5 da 0.506: o ciclo de vida das pages contra
# uma shell viva no compositor aninhado.
#
# O critério 4 (Esc e clique fora) NÃO está aqui, e não por esquecimento:
# provar Esc exige teclar de verdade, e não há injeção de input escopada a um
# compositor nesta máquina (o `ydotool` passa pelo `uinput` do kernel e
# vazaria para a sessão real — ver o fim deste README). Ele vive em
# `tools/manual/lifecycle.sh`, para o Theo olhar.
#
# Nenhuma janela é aberta aqui: tudo se mede pelo que `island <nome> get`
# devolve, inclusive o campo `mirrors`, que existe justamente para tornar a
# decisão 1e.3 observável de fora sem olhar pixel.
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
    else echo "FAIL: $desc — expected [$expected], got [$got]"; fail=1; fi
}

cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true },
      "offset": {"x":0,"y":0}, "size": {"w":40,"h":4}, "gap": 0,
      "layer": "top", "page": "idle" }
  ],
  "pages": {
    "idle": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p1": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p2": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p3": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p4": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p5": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "p6": { "grid": {"cols":10,"rows":4}, "widgets": [] },
    "flash": { "grid": {"cols":10,"rows":4}, "widgets": [], "lifecycle": "popup", "popupTimeout": 1000 },
    "held": { "grid": {"cols":10,"rows":4}, "widgets": [], "lifecycle": "lock" } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f"
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "lifecycle.sh: recusando — instância aninhada não comprovada" >&2
    exit 1
fi

nd() {
    local out; out="$(hyprctl dispatch "$1" 2>&1)" || true
    [[ "$out" == "ok" ]] || { echo "dispatch [$1] falhou: $out" >&2; return 1; }
}

nd 'hl.dsp.focus({ monitor = "HEADLESS-1" })'

export VTNC_CONFIG_DIR="$cfg"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

pg() { "$here/cli/vtnc" island bar get | python3 -c 'import json,sys; print(json.load(sys.stdin).get("page"))'; }
mirror() {
    "$here/cli/vtnc" island bar get | python3 -c "
import json, sys
print(json.load(sys.stdin).get('mirrors', {}).get('$1'))"
}

# Critério 1: o gatilho mora na page (1b.5). A gramática velha some, e some
# dizendo para onde foi — um erro mudo aqui custaria meia hora a quem
# tivesse decorado a forma antiga.
old_grammar=$("$here/cli/vtnc" island bar call p1 2>&1 >/dev/null; true)
check "island <nome> call não existe mais" \
    "$(echo "$old_grammar" | grep -qiE 'page' && echo explica)" "explica"
"$here/cli/vtnc" page p1 call bar >/dev/null; sleep 0.4
check "page <nome> call <island> troca a page ao vivo (critério 1)" "$(pg)" "p1"

# Critério 3: só o espelho do monitor em foco veste a page chamada; os
# outros continuam na idle. É isto que o campo `mirrors` existe para provar.
check "o espelho do monitor em foco veste a page chamada (critério 3)" "$(mirror HEADLESS-1)" "p1"
check "o espelho do outro monitor continua na idle (critério 3)" "$(mirror HEADLESS-2)" "idle"

# Critério 2: a pilha guarda cinco. Seis chamadas, e a mais velha cai.
for p in p2 p3 p4 p5 p6; do "$here/cli/vtnc" page "$p" call bar >/dev/null; sleep 0.15; done
sleep 0.4
check "chamar sobre uma page aberta substitui (critério 2)" "$(pg)" "p6"

seq_got=""
for _ in $(seq 1 5); do
    "$here/cli/vtnc" island bar end >/dev/null 2>&1
    sleep 0.25
    seq_got="$seq_got $(pg)"
done
# p1 caiu fora: a pilha só guardou p2..p6 (1e.2).
check "desempilhar volta na ordem inversa e pousa na idle (critério 2)" \
    "$(echo "$seq_got" | xargs)" "p5 p4 p3 p2 idle"

"$here/cli/vtnc" island bar end >/dev/null 2>&1; sleep 0.3
check "end com a pilha vazia não quebra nada" "$(pg)" "idle"

# Critério 5: o popup some sozinho; o lock não.
"$here/cli/vtnc" page flash call bar >/dev/null; sleep 0.3
check "o popup aparece (critério 5)" "$(pg)" "flash"
sleep 1.2
check "o popup some sozinho depois do popupTimeout (critério 5)" "$(pg)" "idle"

"$here/cli/vtnc" page held call bar >/dev/null; sleep 0.3
check "a page lock aparece (critério 5)" "$(pg)" "held"
sleep 2.5
check "a page lock NÃO some sozinha (critério 5)" "$(pg)" "held"
"$here/cli/vtnc" island bar end >/dev/null; sleep 0.4
check "a page lock sai por island end (critério 5)" "$(pg)" "idle"

exit $fail
