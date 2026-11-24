import QtQuick
import "../../core/widget-registry.mjs" as Registry

// The type: vtnc.not-built. A page that says, in the user's own language,
// that it hasn't been built yet.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? Registry.defaultStyleOf("vtnc.not-built")
    readonly property string pageName: widgetConfig.pageName ?? ""

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria o style no primeiro
    // quadro. Tudo o que o type publica (meta.js, `provides`) viaja assim.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.not-built", root.styleName), {
            pageName: Qt.binding(() => root.pageName)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
