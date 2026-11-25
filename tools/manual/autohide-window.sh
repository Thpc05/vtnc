#!/usr/bin/env bash
# Teste manual do autohide no modo `window`, na sua tela, para você olhar.
#
#   tools/manual/autohide-window.sh
#
# Sobe uma shell de teste com UMA island vermelha no topo, em autohide
# window, leva você para um workspace vazio e fica imprimindo o que o
# Hyprland acha da reserva. Ctrl-C devolve tudo: seus workspaces, seu
# cursor, e nenhuma reserva sobrando.
#
# Nada da sua configuração é tocado: a shell de teste roda com um
# VTNC_CONFIG_DIR temporário.
#
# POR QUE ISTO PARECE QUEBRADO SE VOCÊ TESTAR DO JEITO ÓBVIO
#
# A Settings abre junto com a shell (decisão 1d.6) e é uma janela comum do
# Hyprland. No modo `window` ela conta como "existe janela" — então, se você
# simplesmente subir a vtnc e olhar, a island nasce escondida e parece que o
# autohide ligou sozinho. Não ligou: ele está reagindo à Settings. Por isso
# este script sobe a shell num workspace descartável, deixa a Settings lá, e
# só então te leva para o workspace de teste.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cfg=$(mktemp -d)

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "Isto precisa rodar dentro de uma sessão do Hyprland." >&2
    exit 1
fi

readarray -t STATE < <(hyprctl monitors -j | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    print(m["name"], m["activeWorkspace"]["id"], 1 if m["focused"] else 0)')
HOME_FOCUS=$(hyprctl monitors -j | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    if m["focused"]: print(m["name"])')
read -r CUR_X CUR_Y <<<"$(hyprctl cursorpos -j \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["x"], d["y"])')"

readarray -t FREE < <(hyprctl workspaces -j | python3 -c '
import json, sys
used = {w["id"] for w in json.load(sys.stdin) if "id" in w}
free = [i for i in range(3, 80) if i not in used]
print(free[0]); print(free[1])')
PARK=${FREE[0]}; TEST_WS=${FREE[1]}

# Guarda contra rodar duas vezes: o Ctrl-C sai por `exit`, que dispara o
# trap de EXIT, que é quem de fato limpa.
cleaned=0
cleanup() {
    [[ "$cleaned" == 1 ]] && return 0
    cleaned=1
    echo
    echo "devolvendo..."
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null
    sleep 0.8
    for line in "${STATE[@]}"; do
        set -- $line
        hyprctl dispatch "hl.dsp.focus({ monitor = \"$1\" })" >/dev/null
        hyprctl dispatch "hl.dsp.focus({ workspace = $2 })" >/dev/null
    done
    hyprctl dispatch "hl.dsp.focus({ monitor = \"$HOME_FOCUS\" })" >/dev/null
    hyprctl dispatch "hl.dsp.cursor.move({ x = $CUR_X, y = $CUR_Y })" >/dev/null
    rm -rf "$cfg"
    hyprctl monitors -j | python3 -c 'import json,sys
for m in json.load(sys.stdin):
    print("   ", m["name"], "ws", m["activeWorkspace"]["name"], "reserved", m["reserved"])'
}
# Só EXIT limpa. Ctrl-C e TERM apenas pedem a saída: um `trap cleanup INT`
# roda a limpeza e devolve o controle para o laço, que segue girando com a
# shell de teste já morta — foi o que aconteceu na primeira versão disto, e
# só um `kill -9` resolvia.
trap cleanup EXIT
trap 'exit 130' INT TERM

# Island bem visível: 6 células de altura, vermelha, na borda de cima.
cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "autohide": { "enabled": false, "mode": "always", "distance": 3, "fade": 200, "slideSpeed": 250, "shrinkSize": 1 },
  "islands": [
    { "name": "testbar", "anchor": { "top": true, "left": true, "right": true },
      "offset": {"x":0,"y":0}, "size": {"w":40,"h":6}, "gap": 0,
      "layer": "top", "page": "idle", "autohide": true, "autohideMode": "window" }
  ],
  "pages": { "idle": { "grid": {"cols":10,"rows":6},
    "widgets": [ {"module":"vtnc.square","face":"default","text":"autohide window","cell":{"x":0,"y":0,"w":10,"h":6}} ] } } }
JSON

echo "monitor em foco: $HOME_FOCUS"
echo "workspace da Settings (descartável): $PARK      workspace de teste: $TEST_WS"
echo

hyprctl dispatch "hl.dsp.focus({ workspace = $PARK })" >/dev/null
sleep 0.4

export VTNC_CONFIG_DIR="$cfg"
qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done

# Esperar a CLI responder NAO basta: a janela da Settings mapeia depois
# disso, e se o workspace já tiver mudado ela nasce no workspace de teste —
# onde conta como "existe janela" e esconde a island de saída, que é
# justamente o que este arranjo quer evitar. Espere a janela existir.
for _ in $(seq 1 100); do
    hyprctl clients -j | python3 -c '
import json, sys
sys.exit(0 if any("quickshell" in (c.get("class") or "").lower()
                  for c in json.load(sys.stdin)) else 1)' && break
    sleep 0.2
done
sleep 0.5

hyprctl dispatch "hl.dsp.focus({ workspace = $TEST_WS })" >/dev/null
sleep 1.5

# E confirme que ela realmente ficou para trás.
leaked=$(hyprctl clients -j | python3 -c "
import json, sys
print(sum(1 for c in json.load(sys.stdin)
          if c['workspace'].get('id') == $TEST_WS))")
if [[ "${leaked:-0}" != 0 ]]; then
    echo "AVISO: $leaked janela(s) nasceram no workspace de teste $TEST_WS —"
    echo "a leitura do modo window vai sair errada. Feche-as antes de confiar"
    echo "no que aparecer abaixo."
fi

cat <<EOF
================================================================
Você está no workspace $TEST_WS, vazio. A island deve estar VISÍVEL
no topo — sem nenhuma janela aqui, o modo window não esconde nada.

O que fazer, nesta ordem:

  1. Abra um terminal aqui (super+Q, ou o que for o seu atalho).
     -> a island tem de sumir deslizando para cima, e o terminal
        tem de ocupar os 48px que ela estava reservando.

  2. Encoste o mouse na borda DE CIMA da tela.
     -> ela tem de voltar, por cima da janela, enquanto o mouse
        estiver na faixa de 3 células (24px).

  3. Afaste o mouse.
     -> ela some de novo.

  4. Feche o terminal.
     -> ela volta e fica, e a reserva volta com ela.

A linha abaixo atualiza sozinha. "reserved topo" é o que o Hyprland
de fato reservou: 48 com a island presente, 0 com ela escondida.

Ctrl-C para devolver tudo.
================================================================

EOF

while true; do
    res=$(hyprctl monitors -j | python3 -c "
import json, sys
for m in json.load(sys.stdin):
    if m['name'] == '$HOME_FOCUS': print(m['reserved'][1])" 2>/dev/null)
    n=$(hyprctl clients -j | python3 -c "
import json, sys
print(sum(1 for c in json.load(sys.stdin)
          if c['workspace'].get('id') == $TEST_WS))" 2>/dev/null)
    cur=$(hyprctl cursorpos -j \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print("%s,%s" % (d["x"], d["y"]))' 2>/dev/null)
    printf '\r  janelas no workspace: %-3s   reserved topo: %-4s   cursor: %-12s' \
        "${n:-?}" "${res:-?}" "${cur:-?}"
    sleep 0.3
done
