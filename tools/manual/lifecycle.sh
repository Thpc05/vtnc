#!/usr/bin/env bash
# Teste manual do ciclo de vida das pages (0.506): Esc, popup, lock, e uma
# prova automática de que a page chamada não migra de monitor, na sua tela,
# para você olhar.
#
#   tools/manual/lifecycle.sh
#
# Sobe uma shell de teste com UMA island ("testbar") no topo, idle na page
# "idle", leva você para um workspace vazio e deixa você mesmo chamar as
# outras pages pela CLI, noutro terminal. Ctrl-C devolve tudo.
#
# Nada da sua configuração é tocado: a shell de teste roda com um
# VTNC_CONFIG_DIR temporário, que este script também exporta no terminal
# onde ele roda — abra o SEGUNDO terminal (o que vai digitar os comandos
# vtnc) a partir deste, ou exporte a mesma variável nele, senão a CLI fala
# com a config errada.
#
# POR QUE ISTO PRECISA SER OLHADO, NÃO MEDIDO
#
# Esc é limpo: ele só funciona quando a superfície tem foco de teclado, e dá
# para confirmar isso de fora (WlrKeyboardFocus). Clique fora SAIU do
# contrato desta etapa (decisão 1e.4b) — uma superfície wlr-layer-shell não
# enxerga clique fora dela, e a única saída direta (uma superfície
# transparente de tela inteira) rouba o clique de todo mundo atrás dela;
# meio comportamento (reagir só a clicar numa janela de verdade, não ao
# desktop vazio nem a outra superfície do vtnc) foi decidido pior que
# nenhum. Não há passo de clique fora aqui por isso, de propósito.
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

readarray -t FREE < <(hyprctl workspaces -j | python3 -c '
import json, sys
used = {w["id"] for w in json.load(sys.stdin) if "id" in w}
free = [i for i in range(3, 80) if i not in used]
print(free[0]); print(free[1])')
PARK=${FREE[0]}; TEST_WS=${FREE[1]}

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
    rm -rf "$cfg"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "islands": [
    { "name": "testbar", "anchor": { "top": true, "left": true, "right": true },
      "offset": {"x":0,"y":0}, "size": {"w":40,"h":4}, "gap": 0,
      "layer": "top", "page": "idle" }
  ],
  "pages": {
    "idle": { "grid": {"cols":10,"rows":4},
      "widgets": [ {"module":"vtnc.square","face":"default","text":"idle","cell":{"x":0,"y":0,"w":10,"h":4}} ] },
    "calledplain": { "grid": {"cols":10,"rows":4}, "lifecycle": "called", "needsKeyboard": false,
      "widgets": [ {"module":"vtnc.square","face":"default","text":"called (no kb)","cell":{"x":0,"y":0,"w":10,"h":4}} ] },
    "modal": { "grid": {"cols":10,"rows":4}, "lifecycle": "called", "needsKeyboard": true,
      "widgets": [ {"module":"vtnc.square","face":"default","text":"called (needs kb)","cell":{"x":0,"y":0,"w":10,"h":4}} ] },
    "popup": { "grid": {"cols":10,"rows":4}, "lifecycle": "popup", "popupTimeout": 8000,
      "widgets": [ {"module":"vtnc.square","face":"default","text":"popup (8s or x)","cell":{"x":0,"y":0,"w":10,"h":4}} ] },
    "locked": { "grid": {"cols":10,"rows":4}, "lifecycle": "lock",
      "widgets": [ {"module":"vtnc.square","face":"default","text":"lock (CLI only)","cell":{"x":0,"y":0,"w":10,"h":4}} ] }
  }
}
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
sleep 0.5

hyprctl dispatch "hl.dsp.focus({ workspace = $TEST_WS })" >/dev/null
sleep 0.5

# Prova automática da decisão 1e.3b: a page chamada fica no monitor onde
# foi chamada, mesmo depois que o foco muda — ela não migra atrás do olhar
# do usuário. Só roda de verdade com dois monitores físicos; com um só,
# não há para onde mover o foco, então o script avisa e segue sem ela.
other_monitor=$(hyprctl monitors -j | python3 -c "
import json, sys
mons = [m['name'] for m in json.load(sys.stdin)]
mons = [m for m in mons if m != '$HOME_FOCUS']
print(mons[0] if mons else '')")

echo "================================================================"
if [[ -z "$other_monitor" ]]; then
    echo "Só um monitor conectado — pulando a prova automática de que a page"
    echo "chamada não migra (decisão 1e.3b): precisa de dois."
else
    echo "Provando a decisão 1e.3b (não migra) entre $HOME_FOCUS e $other_monitor..."
    "$here/cli/vtnc" page calledplain call testbar >/dev/null
    sleep 0.4
    before=$("$here/cli/vtnc" island testbar get)
    hyprctl dispatch "hl.dsp.focus({ monitor = \"$other_monitor\" })" >/dev/null
    sleep 0.4
    after=$("$here/cli/vtnc" island testbar get)
    hyprctl dispatch "hl.dsp.focus({ monitor = \"$HOME_FOCUS\" })" >/dev/null
    "$here/cli/vtnc" island testbar end >/dev/null

    python3 -c "
import json, sys
home, other = '$HOME_FOCUS', '$other_monitor'
before, after = json.loads('''$before'''), json.loads('''$after''')
checks = [
    ('antes de mudar o foco, $home veste a page chamada',
        before['mirrors'].get(home) == 'calledplain'),
    ('antes de mudar o foco, $other continua na idle',
        before['mirrors'].get(other) == 'idle'),
    ('depois de mudar o foco para $other, $home AINDA veste a page chamada (não migrou)',
        after['mirrors'].get(home) == 'calledplain'),
    ('depois de mudar o foco para $other, $other continua na idle (não herdou)',
        after['mirrors'].get(other) == 'idle'),
]
ok = True
for desc, passed in checks:
    print(('OK: ' if passed else 'FAIL: ') + desc)
    ok = ok and passed
sys.exit(0 if ok else 1)
" || echo "AVISO: a prova automática falhou — leia as linhas FAIL acima."
fi
echo "================================================================"
echo

cat <<EOF
================================================================
Você está no workspace $TEST_WS. "testbar" está no topo, mostrando idle.

Noutro terminal, com:  export VTNC_CONFIG_DIR=$cfg
rode os comandos abaixo, um de cada vez, e olhe o que acontece.

1. vtnc page calledplain call testbar
   -> aparece "called (no kb)". Aperte Esc SEM clicar na island antes.
      Não deve fechar ainda — ela só pede foco quando você clica (OnDemand).
      Clique dentro da island, aperte Esc de novo: agora fecha.

2. vtnc page modal call testbar
   -> aparece "called (needs kb)". Aperte Esc direto, SEM clicar.
      Deve fechar na hora — esta page pediu o teclado (Exclusive).

3. vtnc page popup call testbar
   -> aparece "popup (8s or x)". Espere 8 segundos: deve sumir sozinha.
      Chame de novo e desta vez clique no x no canto superior direito:
      deve fechar na hora, sem esperar o tempo.

4. vtnc page locked call testbar
   -> aparece "lock (CLI only)". Esc NÃO deve fechar. Só isto fecha:
      vtnc island testbar end

Ctrl-C aqui devolve tudo (workspace, monitor, a shell de teste).
================================================================
EOF

while true; do
    sleep 1
done
