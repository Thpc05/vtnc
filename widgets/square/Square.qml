import QtQuick
import "../../core/widget-registry.mjs" as Registry

// The type: vtnc.square. A dumb widget — a square with text — that exists
// to prove the type/style split (decision 3.1/3.5) with the least possible
// code. No services: it names none because it needs none.
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? Registry.defaultStyleOf("vtnc.square")
    readonly property string text: widgetConfig.text ?? "square"

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria o style no primeiro
    // quadro. Tudo o que o type publica (meta.js, `provides`) viaja assim.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.square", root.styleName), {
            text: Qt.binding(() => root.text)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
