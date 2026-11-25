#!/usr/bin/env bash
# Camada 3 da 0.510, critérios 2, 5 e 6: as opções de face contra uma shell
# viva.
#
# O que só se mede aqui, e não em node: que a shell RESOLVE as opções — o
# guardado quando serve, o default declarado quando não — e que ela recusa,
# pela CLI, o valor que a face não pediu. A decisão 3.4d é toda sobre esse
# "quem decide", e medir num .mjs só prova a função; medir aqui prova que o
# caminho inteiro, da CLI à shell, obedece.
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

# Duas islands na mesma page de novo: trocar a face é mexer na page, e a
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
      "widgets": [ { "module": "vtnc.clock", "cell": {"x":0,"y":0,"w":6,"h":2} } ] } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f" || exit 1
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "face-options.sh: RECUSANDO — instância aninhada não comprovada" >&2
    exit 1
fi

export VTNC_CONFIG_DIR="$cfg"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

v() { "$here/cli/vtnc" "$@"; }
# "module:face" de cada widget, como a SHELL o vê — não como o config.json o
# escreveu.
seen() {
    v island "$1" get | python3 -c '
import json, sys
print(" ".join(w["module"] + ":" + str(w["face"]) for w in json.load(sys.stdin).get("widgets", [])))'
}

# As opções que a SHELL resolveu para aquele widget, em ordem de chave.
opts() {
    v island bar get | python3 -c '
import json, sys
w = json.load(sys.stdin)["widgets"]['"$1"']["options"]
print(" ".join(k + "=" + str(w[k]) for k in sorted(w)))'
}
set_widgets() { v page shared set widgets "$1" >/dev/null 2>&1; }
# A CLI escreve no stdout e devolve 0; o erro vai para o stderr.
refused() { v page shared set widgets "$1" 2>&1 >/dev/null; }

# ------------------------------- critério 5: os defaults que a face declarou
check "sem nada guardado, a shell entrega os defaults declarados pela face" \
    "$(opts 0)" "align=center color=text fontSize=20 showSeconds=True"

# ------------------------------------------- critério 6: mudar uma opção
set_widgets '[{"module":"vtnc.clock","face":"digital","cell":{"x":0,"y":0,"w":6,"h":2},
               "options":{"digital":{"fontSize":32,"showSeconds":false}}}]'
sleep 0.6
check "mudar uma opção chega na shell viva (critério 6)" \
    "$(opts 0)" "align=center color=text fontSize=32 showSeconds=False"

# ---------------------------- critério 2: a shell recusa o que a face não pediu
check "um número fora do min/max é recusado antes do config.json (critério 2)" \
    "$(refused '[{"module":"vtnc.clock","face":"digital","cell":{"x":0,"y":0,"w":6,"h":2},"options":{"digital":{"fontSize":500}}}]' | grep -c 'entre 8 e 72')" "1"
check "uma escolha fora da lista é recusada" \
    "$(refused '[{"module":"vtnc.clock","face":"digital","cell":{"x":0,"y":0,"w":6,"h":2},"options":{"digital":{"align":"diagonal"}}}]' | grep -c 'left, center, right')" "1"
check "um papel de cor que não existe é recusado" \
    "$(refused '[{"module":"vtnc.clock","face":"digital","cell":{"x":0,"y":0,"w":6,"h":2},"options":{"digital":{"color":"#ff0000"}}}]' | grep -c 'papel de cor')" "1"
check "e nenhuma das três recusas mexeu no que estava guardado" \
    "$(opts 0)" "align=center color=text fontSize=32 showSeconds=False"

# ------------------------------------- 4.4: trocar de face e voltar
set_widgets '[{"module":"vtnc.clock","face":"compact","cell":{"x":0,"y":0,"w":6,"h":2},
               "options":{"digital":{"fontSize":32,"showSeconds":false},"compact":{"showSeconds":true}}}]'
sleep 0.6
check "a face compact vê as opções DELE, não as do digital (4.4)" \
    "$(opts 0)" "fill=accent showSeconds=True"

set_widgets '[{"module":"vtnc.clock","face":"digital","cell":{"x":0,"y":0,"w":6,"h":2},
               "options":{"digital":{"fontSize":32,"showSeconds":false},"compact":{"showSeconds":true}}}]'
sleep 0.6
check "voltar ao digital reencontra as opções dele intactas (4.4)" \
    "$(opts 0)" "align=center color=text fontSize=32 showSeconds=False"

# --------------------- opção guardada que nao serve mais cai no default
# A config é um arquivo que o usuário edita à mão: um valor que a face não
# aceita mais não pode chegar torto à face nem derrubar o desenho.
python3 - "$cfg/config.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
doc = json.load(open(path))
doc["pages"]["shared"]["widgets"][0]["options"]["digital"]["fontSize"] = 999
json.dump(doc, open(path, "w"), indent=2)
PYEOF
sleep 0.8
check "um valor impossível escrito à mão no arquivo cai no default" \
    "$(opts 0)" "align=center color=text fontSize=20 showSeconds=False"

exit "$fail"
