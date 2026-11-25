import QtQuick
import "../../core/widget-registry.mjs" as Registry

// The module: vtnc.not-built. A page that says, in the user's own language,
// that it hasn't been built yet.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string faceName: widgetConfig.face ?? Registry.defaultFaceOf("vtnc.not-built")
    readonly property string pageName: widgetConfig.pageName ?? ""

    onFaceNameChanged: root.loadFace()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria a face no primeiro
    // quadro. Tudo o que o module publica (meta.js, `provides`) viaja assim.
    function loadFace() {
        faceLoader.setSource(Registry.resolvedFacePath("vtnc.not-built", root.faceName), {
            pageName: Qt.binding(() => root.pageName)
        });
    }

    Loader {
        id: faceLoader
        anchors.fill: parent
        Component.onCompleted: root.loadFace()
    }
}
