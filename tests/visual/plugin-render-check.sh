#!/usr/bin/env bash
# Camada 4 da 0.512: o widget de um plugin de terceiro, desenhado.
#
# Por que isto existe separado do tests/cli/plugins.sh: o `island get`
# daquele teste lê a CONFIG, não a árvore viva — ele prova que a shell
# resolveu o module e a face do plugin, e não que alguma coisa apareceu na
# tela. A prova de que desenha é esta, e é olhada (decisão 17.2).
#
# O plugin é escrito aqui, numa pasta descartável, e apagado no fim: um
# plugin de teste versionado dentro do repositório vira parte da shell sem
# ninguém perceber, e aí não prova mais nada.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="${1:-$here/plugin-render.png}"
own_nest=""
harness="$root/.plugin-render-test.qml"
plugins=$(mktemp -d)

cleanup() {
    if [[ -n "$own_nest" ]]; then
        "$root/tools/headless/nested.sh" stop "$own_nest" || true
        rm -f "$own_nest"
    fi
    rm -f "$harness"
    rm -rf "$plugins"
}
trap cleanup EXIT

# ---------------------------------------------------- o plugin descartável
mkdir -p "$plugins/shapes/modules/hexclock/faces/neon"
cat >"$plugins/shapes/plugin.json" <<'JSON'
{ "id": "shapes", "version": "1.0.0", "pluginApi": 1, "author": "ninguem",
  "description": "A disposable plugin, written by the test.",
  "modules": ["modules/hexclock"], "faces": ["modules/hexclock/faces/neon"] }
JSON
cat >"$plugins/shapes/modules/hexclock/meta.json" <<'JSON'
{ "module": "hexclock", "title": "Hex clock", "component": "HexClock.qml",
  "services": [], "defaultFace": "neon", "placeable": true,
  "defaultCell": { "w": 6, "h": 4 },
  "provides": [ { "name": "label", "kind": "string",
                  "doc": "O texto que este module entrega as faces dele." } ] }
JSON
# O module de terceiro faz o mesmo que os do vtnc: pergunta ao registro
# onde esta a face pedida e carrega por URL.
cat >"$plugins/shapes/modules/hexclock/HexClock.qml" <<QML
import QtQuick
import "file:$root/core" as VtncCore

Item {
    id: root
    property var widgetConfig: ({})
    readonly property string faceName: widgetConfig.face ?? "neon"
    readonly property string label: "plugin!"

    // O binding no catalog nao e enfeite, e o que faz este widget
    // aparecer: o registro que ESTE arquivo enxerga e uma copia (ver
    // page/Page.qml), e a copia ainda esta varrendo o disco quando o
    // module e criado. Quem pergunta uma vez so em Component.onCompleted
    // recebe "" e nunca mais desenha - foi o que aconteceu na primeira
    // vez que este render rodou.
    readonly property string faceUrl: VtncCore.PluginRegistry.catalog
        ? VtncCore.PluginRegistry.resolvedFaceUrl("shapes.hexclock", root.faceName) : ""

    onFaceUrlChanged: root.loadFace()
    function loadFace() {
        if (root.faceUrl === "") return;
        faceLoader.setSource(root.faceUrl, { label: Qt.binding(() => root.label) });
    }
    Loader { id: faceLoader; anchors.fill: parent; Component.onCompleted: root.loadFace() }
}
QML
cat >"$plugins/shapes/modules/hexclock/faces/neon/meta.json" <<'JSON'
{ "face": "neon", "module": "shapes.hexclock", "title": "Neon", "component": "Neon.qml" }
JSON
cat >"$plugins/shapes/modules/hexclock/faces/neon/Neon.qml" <<'QML'
import QtQuick
Item {
    id: face
    required property string label
    property var options: ({})
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: "#7a1f5a"
        border.color: "#ff5fc8"
        border.width: 1
        Text { anchors.centerIn: parent; text: face.label; color: "#ffd6f1" }
    }
}
QML

# ---------------------------------------------------- a cena
cat >"$harness" <<'QML'
import QtQuick
import QtQuick.Window
import Quickshell
import "./page"

// Uma page com um widget do vtnc e um de um plugin de terceiro, lado a
// lado. Se os dois desenham, o carregador nao tem caso especial para o
// proprio vtnc - que e a coisa que este passo promete.
Window {
    width: 400
    height: 120
    visible: true
    color: "#1b1b1b"

    Page {
        id: page
        anchors.fill: parent
        cellPx: 8
        pageConfig: ({
            "grid": { "cols": 50, "rows": 15 },
            "widgets": [
                { "module": "vtnc.clock", "face": "digital", "cell": { "x": 1, "y": 1, "w": 12, "h": 4 } },
                { "module": "shapes.hexclock", "cell": { "x": 15, "y": 1, "w": 10, "h": 4 } },
                { "module": "nao.existe", "cell": { "x": 27, "y": 1, "w": 6, "h": 4 } }
            ]
        })
    }

    // A espera nao e folclore: a listagem da pasta de plugins e a unica
    // parte assincrona da varredura (FolderListModel), entao o plugin
    // instalado entra no catalogo um instante depois de a shell subir.
    // Num Qt.callLater o widget dele ainda nao existe - e exatamente o
    // que este render pegou na primeira vez que rodou.
    Timer {
        interval: 1500
        running: true
        onTriggered: {
            const out = Quickshell.env("VTNC_RENDER_OUT");
            page.grabToImage(function (result) {
                const ok = result.saveToFile(out);
                if (!ok) console.warn("plugin-render: saveToFile failed for", out);
                Qt.exit(ok ? 0 : 1);
            });
        }
    }
}
QML

if [[ -z "${NESTED_PID:-}" ]]; then
    own_nest=$(mktemp)
    if ! "$root/tools/headless/nested.sh" start "$own_nest"; then
        echo "FAIL: the nested test compositor did not come up."
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$own_nest"
fi

case "$plugins" in
    /tmp/*) ;;
    *) echo "plugin-render-check.sh: RECUSANDO — a pasta de plugins não é descartável" >&2; exit 1 ;;
esac

rm -f "$out"
log=$(VTNC_RENDER_OUT="$out" VTNC_PLUGIN_DIR="$plugins" \
      timeout 30 env QT_QPA_PLATFORM=wayland qs -p "$harness" -n 2>&1)
status=$?

if [[ $status -eq 124 ]]; then
    echo "FAIL: the render timed out — grabToImage never called back."
    echo "$log"
    exit 1
fi
if [[ ! -s "$out" ]]; then
    echo "FAIL: no image produced (qs exited $status)."
    echo "$log"
    exit 1
fi

[[ -n "$log" ]] && echo "$log"
echo "OK: rendered to $out — olhe: o relógio do vtnc e o widget rosa do plugin"
echo "    têm de aparecer os dois, e o module inexistente não pode deixar buraco."
exit 0
