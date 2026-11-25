#!/usr/bin/env bash
# Camada 3 da 0.512: um plugin que a shell nunca viu, montado numa pasta
# descartável, carregado por varredura numa shell viva.
#
# É aqui que o passo prova o que interessa, e que node nenhum prova: que o
# module de um terceiro **desenha** — o `island get` devolve o widget dele
# dentro de uma page, com a face dele resolvida, exatamente como devolve um
# widget do vtnc. E que um plugin fora da faixa de API continua listado,
# com o motivo escrito, em vez de sumir sem explicação.
#
# A pasta de plugins é descartável e a recusa é explícita, no molde da
# 0.507: se VTNC_PLUGIN_DIR não apontar para a pasta temporária que este
# script criou, ele não roda.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cfg=$(mktemp -d); env_f=$(mktemp); plugins=$(mktemp -d)
real_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
fail=0

cleanup() {
    [[ -n "${QS_PID:-}" ]] && kill "$QS_PID" 2>/dev/null
    "$here/tools/headless/nested.sh" stop "$env_f"
    rm -rf "$cfg" "$env_f" "$plugins"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then echo "OK: $desc"
    else echo "FAIL: $desc — esperado [$expected], obtido [$got]"; fail=1; fi
}

# --------------------------------------------------- o plugin descartável
# Escrito aqui, inteiro, e não copiado de uma pasta versionada: um plugin
# de teste que mora no repositório acaba virando parte da shell sem
# ninguém perceber, e aí ele não prova mais nada.
write_plugin() { # $1 = pasta, $2 = id, $3 = pluginApi
    local root="$1/$2"
    mkdir -p "$root/modules/hexclock/faces/neon"
    cat >"$root/plugin.json" <<JSON
{ "id": "$2", "version": "1.0.0", "pluginApi": $3, "author": "ninguem",
  "description": "A disposable plugin, written by the test.",
  "modules": ["modules/hexclock"],
  "faces": ["modules/hexclock/faces/neon"] }
JSON
    cat >"$root/modules/hexclock/meta.json" <<'JSON'
{ "module": "hexclock", "title": "Hex clock", "component": "HexClock.qml",
  "services": [], "defaultFace": "neon", "placeable": true,
  "defaultCell": { "w": 4, "h": 2 },
  "provides": [ { "name": "label", "kind": "string",
                  "doc": "O texto que este module entrega as faces dele." } ] }
JSON
    # O `import "file:..."` com o caminho da shell e exatamente o que a
    # 4.6 diz que um plugin consegue fazer e a shell nao impede: ele
    # alcanca o core inteiro. Aqui e para chegar ao registro, que e o uso
    # legitimo; a regra que separa um do outro e revisao, nao tecnica.
    cat >"$root/modules/hexclock/HexClock.qml" <<QML
import QtQuick
import "file:$here/core" as VtncCore

// Um module de terceiro: ele pergunta ao registro onde esta a face dele e
// carrega por URL, do mesmo jeito que os modules do vtnc fazem.
Item {
    id: root
    property var widgetConfig: ({})
    readonly property string faceName: widgetConfig.face ?? "neon"
    readonly property string label: "hex"

    // O binding no catalog nao e enfeite: o registro que ESTE arquivo
    // enxerga e uma copia (ver page/Page.qml), e a copia ainda esta
    // varrendo o disco quando o module e criado.
    readonly property string faceUrl: VtncCore.PluginRegistry.catalog
        ? VtncCore.PluginRegistry.resolvedFaceUrl("$2.hexclock", root.faceName) : ""

    onFaceUrlChanged: root.loadFace()
    function loadFace() {
        if (root.faceUrl === "") return;
        faceLoader.setSource(root.faceUrl, { label: Qt.binding(() => root.label) });
    }
    Loader { id: faceLoader; anchors.fill: parent; Component.onCompleted: root.loadFace() }
}
QML
    cat >"$root/modules/hexclock/faces/neon/meta.json" <<JSON
{ "face": "neon", "module": "$2.hexclock", "title": "Neon", "component": "Neon.qml",
  "options": [ { "key": "glow", "kind": "toggle", "title": "Glow", "default": true } ] }
JSON
    cat >"$root/modules/hexclock/faces/neon/Neon.qml" <<'QML'
import QtQuick
Item {
    required property string label
    property var options: ({})
    Rectangle { anchors.fill: parent; color: "#ff00aa"
        Text { anchors.centerIn: parent; text: parent.parent.label; color: "white" } }
}
QML
}

write_plugin "$plugins" shapes 1
# O segundo pede um nível de API que esta shell não suporta. 9999 é
# deliberadamente absurdo: o teste não deve passar a falhar só porque a
# faixa de API da shell cresceu um número.
write_plugin "$plugins" fromthefuture 9999

cat >"$cfg/config.json" <<'JSON'
{ "cell": { "base": 8 }, "monitors": {},
  "islands": [
    { "name": "bar", "anchor": { "top": true, "left": true, "right": true },
      "offset": {"x":0,"y":0}, "size": {"w":40,"h":4}, "gap": 0,
      "layer": "top", "page": "shared" }
  ],
  "pages": {
    "shared": { "grid": {"cols":10,"rows":4}, "widgets": [] } } }
JSON

"$here/tools/headless/nested.sh" start "$env_f" || exit 1
# shellcheck disable=SC1090
source "$env_f"
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || "$HYPRLAND_INSTANCE_SIGNATURE" == "$real_sig" ]]; then
    echo "plugins.sh: RECUSANDO — instância aninhada não comprovada" >&2
    exit 1
fi

export VTNC_CONFIG_DIR="$cfg"
export VTNC_PLUGIN_DIR="$plugins"
case "$VTNC_PLUGIN_DIR" in
    /tmp/*) ;;
    *) echo "plugins.sh: RECUSANDO — VTNC_PLUGIN_DIR não é a pasta descartável" >&2; exit 1 ;;
esac

QT_QPA_PLATFORM=wayland qs -p "$here" -n >"$cfg/qs.log" 2>&1 &
QS_PID=$!
for _ in $(seq 1 80); do "$here/cli/vtnc" island list >/dev/null 2>&1 && break; sleep 0.2; done
sleep 1

v() { "$here/cli/vtnc" "$@"; }
plugin_field() { # $1 = id, $2 = campo
    v plugin list | python3 -c "
import json, sys
for p in json.load(sys.stdin):
    if p['id'] == '$1': print(json.dumps(p['$2'])); break
else: print('AUSENTE')"
}
seen() {
    v island bar get | python3 -c '
import json, sys
print(" ".join(w["module"] + ":" + (w["face"] or "-") for w in json.load(sys.stdin).get("widgets", [])))'
}

# ------------------------------------------- critério 3: a varredura acha
check "a varredura acha os dois plugins instalados, além do próprio vtnc" \
    "$(v plugin list | python3 -c 'import json,sys; print(" ".join(sorted(p["id"] for p in json.load(sys.stdin))))')" \
    "fromthefuture shapes vtnc"
check "o vtnc aparece como plugin embutido, carregado pela mesma varredura" \
    "$(plugin_field vtnc builtin)" "true"

# ------------------------------------------- o plugin de terceiro carrega
check "o module do plugin de terceiro entra no catálogo da shell" \
    "$(plugin_field shapes modules)" '["shapes.hexclock"]'
check "e a face dele também" \
    "$(plugin_field shapes faces)" '["shapes.hexclock/neon"]'
check "sem problema nenhum" "$(plugin_field shapes problems)" "[]"

# --------------------------------- critério 2: fora da faixa, listado e mudo
check "o plugin fora da faixa continua listado, com a versão que ele declarou" \
    "$(plugin_field fromthefuture version)" '"1.0.0"'
check "mas marcado como incompatível" "$(plugin_field fromthefuture compatible)" "false"
check "e não carregado" "$(plugin_field fromthefuture loaded)" "false"
check "o motivo diz que foi a FAIXA de API, não um erro de carga" \
    "$(plugin_field fromthefuture problems | grep -c 'fora da faixa')" "1"
check "e nenhum module dele entra no catálogo" "$(plugin_field fromthefuture modules)" "[]"

# ------------------- o que node nenhum prova: o widget de terceiro DESENHA
v page shared set widgets \
    '[{"module":"shapes.hexclock","cell":{"x":0,"y":0,"w":4,"h":2}}]' >/dev/null
sleep 0.8
check "o widget do plugin de terceiro aparece na page, com a face dele resolvida" \
    "$(seen)" "shapes.hexclock:neon"
check "e a shell resolveu as opções que a face dele declarou" \
    "$(v island bar get | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["widgets"][0]["options"]))')" \
    '{"glow": true}'

# O do futuro não desenha: o widget fica na config, a shell não o monta.
v page shared set widgets \
    '[{"module":"fromthefuture.hexclock","cell":{"x":0,"y":0,"w":4,"h":2}}]' >/dev/null
sleep 0.8
check "um widget de plugin incompatível fica na config mas não vira face nenhuma" \
    "$(seen)" "fromthefuture.hexclock:-"

exit $fail
