#!/usr/bin/env bash
# Camada 3 da 0.507, critérios 1 a 5: os keybinds do Hyprland medidos contra
# `hyprctl binds -j` dentro do compositor aninhado, que é a medida exata deste
# passo do mesmo jeito que o `reserved` do `monitors -j` foi o da 0.504.
#
# O PERIGO DESTE TESTE (risco `gerar-arquivo-no-hypr-real`): é o primeiro que
# faz a shell escrever FORA da pasta de configuração dela, e rodar
# `hyprctl reload` depois. Se o redirecionamento falhar, ele gera arquivo na
# configuração real do Theo e recarrega a sessão dele — e, por causa do
# unbind, pode derrubar atalhos que ele usa. Daí a mesma forma do trap da
# 0.505: `safe` só vira 1 depois da prova, e nada que escreva roda sem ela.
# A prova não olha a variável de ambiente: ela pergunta ao próprio
# cli/lib/hyprland-paths.js para onde o caminho resolve.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp=$(mktemp -d); env_f=$(mktemp)
real_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
fail=0
safe=0

cfgroot="$tmp/config"          # vira o XDG_CONFIG_HOME de todo mundo
hyprdir="$cfgroot/hypr"
vtncdir="$hyprdir/vtnc"
luafile="$vtncdir/keybinds.lua"
vtnc_cfg="$tmp/vtnc"           # a config da própria shell
mkdir -p "$hyprdir" "$vtnc_cfg"

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null
    "$here/tools/headless/nested.sh" stop "$env_f"
    rm -rf "$tmp" "$env_f"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then echo "OK: $desc"
    else echo "FAIL: $desc — esperado [$expected], obtido [$got]"; fail=1; fi
}

# ---------------------------------------------------------------- a prova
# Pergunta ao módulo que a shell de fato usa para onde ele escreve, com o
# ambiente que a shell de fato vai receber. Comparar a variável não serviria:
# o que importa é o caminho resolvido.
resolved=$(cd "$here" && XDG_CONFIG_HOME="$cfgroot" node -e \
    'import("./cli/lib/hyprland-paths.js").then(m => console.log(m.hyprKeybindsFile()))')
real_resolved=$(cd "$here" && env -u XDG_CONFIG_HOME node -e \
    'import("./cli/lib/hyprland-paths.js").then(m => console.log(m.hyprKeybindsFile()))')

if [[ "$resolved" != "$luafile" ]]; then
    echo "hyprland-keybinds.sh: RECUSANDO — o caminho resolvido [$resolved] não é o descartável [$luafile]" >&2
    exit 1
fi
if [[ "$resolved" == "$real_resolved" ]]; then
    echo "hyprland-keybinds.sh: RECUSANDO — o caminho resolvido é o real [$real_resolved]" >&2
    exit 1
fi
case "$resolved" in
    "$tmp"/*) ;;
    *) echo "hyprland-keybinds.sh: RECUSANDO — [$resolved] está fora da pasta descartável" >&2; exit 1 ;;
esac
safe=1
echo "OK: o caminho de escrita resolve para a pasta descartável, não para $real_resolved"

# A config do Hyprland aninhado: um bind PRÓPRIO DO USUÁRIO, declarado fora
# da pasta do vtnc (é o critério 4), e o require guardado por pcall — com o
# pcall, o arquivo ainda não existir não derruba a config inteira, que é o
# estado "sem consentimento" do critério 1.
cat >"$hyprdir/hyprland.lua" <<'LUA'
hl.monitor({ output = "HEADLESS-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HEADLESS-2", mode = "2560x1440@60", position = "1920x0", scale = 1 })
hl.config({ misc = { disable_hyprland_logo = true, force_default_wallpaper = 0 } })

hl.bind("SUPER + F3", hl.dsp.exec_cmd("true"))

pcall(require, "vtnc/keybinds")
LUA

export XDG_CONFIG_HOME="$cfgroot"
export NESTED_HYPR_CONFIG="$hyprdir/hyprland.lua"
"$here/tools/headless/nested.sh" start "$env_f" || exit 1
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "hyprland-keybinds.sh: RECUSANDO — instância aninhada não comprovada" >&2
    exit 1
fi

# Quais teclas o compositor registrou, uma por linha, ordenadas.
keys() {
    hyprctl binds -j | python3 -c '
import json, sys
print(" ".join(sorted("%s+%s" % (b.get("modmask"), b.get("key")) for b in json.load(sys.stdin))))'
}
# Espera até `keys` conter (ou não conter) algo, em vez de dormir no escuro.
wait_for() {
    local want="$1" mode="${2:-present}"
    for _ in $(seq 1 40); do
        if [[ "$mode" == "present" ]]; then
            keys | grep -q "$want" && return 0
        else
            keys | grep -q "$want" || return 0
        fi
        sleep 0.25
    done
    return 1
}

cat >"$vtnc_cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {}, "islands": [], "pages": {},
  "hyprland": { "enabled": false, "keybinds": [] } }
JSON

export VTNC_CONFIG_DIR="$vtnc_cfg"
QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$tmp/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" hyprland list >/dev/null 2>&1 && break; sleep 0.2; done

v() { "$here/cli/vtnc" "$@"; }
jq_hypr() { python3 -c 'import json,sys; print(json.load(sys.stdin)'"$1"')'; }

# ------------------------------------------------- critério 1: sem consentimento
[[ "$safe" == 1 ]] || { echo "RECUSANDO: safe não posta"; exit 1; }
v hyprland set keybinds '[{"key":"SUPER + F9","commands":["true"],"enabled":true,"description":"nove"},
                          {"key":"SUPER + F10","commands":["true"],"enabled":true,"description":"dez"}]' >/dev/null
sleep 1.5
check "sem consentimento, a configuração guarda os keybinds editados (critério 1)" \
    "$(v hyprland list | jq_hypr '["keybinds"].__len__()')" "2"
check "e nada existe sob ~/.config/hypr/vtnc (critério 1)" \
    "$([[ -e "$vtncdir" ]] && echo existe || echo ausente)" "ausente"
check "e o compositor só tem o bind do usuário (critério 1)" "$(keys)" "64+F3"

# ------------------------------------------------- critério 2: ligar o consentimento
v hyprland set enabled true >/dev/null
wait_for '64+F9' || true
check "o arquivo Lua passa a existir depois do consentimento (critério 2)" \
    "$([[ -f "$luafile" ]] && echo existe || echo ausente)" "existe"
check "a shell gerou e recarregou sozinha: os dois binds do vtnc entraram (critério 2)" \
    "$(keys)" "64+F10 64+F3 64+F9"
check "o arquivo é Lua, com hl.bind e hl.unbind (critério 2 / 7.3)" \
    "$(grep -cE '^hl\.(un)?bind\(' "$luafile")" "4"

# ------------------------------------------------- critério 4: o bind do usuário
check "o bind próprio do usuário sobrevive a gerar e recarregar (critério 4)" \
    "$(keys | grep -o '64+F3')" "64+F3"
check "o arquivo gerado não nomeia a tecla do usuário (critério 4 / 7.4)" \
    "$(grep -c 'F3' "$luafile")" "0"

# ------------------------------------------------- critério 3: desligar um keybind
v hyprland set keybinds '[{"key":"SUPER + F9","commands":["true"],"enabled":false,"description":"nove"},
                          {"key":"SUPER + F10","commands":["true"],"enabled":true,"description":"dez"}]' >/dev/null
wait_for '64+F9' absent || true
check "desligar um keybind o tira do compositor sem mexer nos outros (critério 3)" \
    "$(keys)" "64+F10 64+F3"
check "a tecla desligada continua desvinculada no arquivo (critério 3 / 7.4)" \
    "$(grep -c 'hl.unbind(\[\[SUPER + F9\]\])' "$luafile")" "1"
check "e ela não é mais vinculada" \
    "$(grep -c 'hl.bind(\[\[SUPER + F9\]\],' "$luafile")" "0"

# ------------------------------------------------- critério 5: regeneração inteira
echo '-- editado na mão, isto tem de desaparecer' >>"$luafile"
check "o aviso de não editar está no arquivo (critério 5)" \
    "$(grep -ci 'DO NOT EDIT' "$luafile")" "1"
v hyprland set keybinds '[{"key":"SUPER + F10","commands":["true","true"],"enabled":true}]' >/dev/null
wait_for '64+F10' || true
sleep 1
check "a edição manual não é preservada (critério 5)" \
    "$(grep -c 'editado na mão' "$luafile")" "0"
check "o arquivo é regenerado inteiro, só com o que a config tem agora (critério 5)" \
    "$(grep -c 'F9' "$luafile")" "0"
check "e o compositor acompanha — o require NÃO ficou em cache entre reloads" \
    "$(keys)" "64+F10 64+F3"

exit $fail
