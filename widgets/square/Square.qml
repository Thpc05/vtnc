import QtQuick
import "../../core/widget-registry.mjs" as Registry
import "../../core/face-schema.mjs" as FaceSchema

// The module: vtnc.square. A dumb widget — a square with text — that exists
// to prove the module/face split (decision 3.1/3.5) with the least possible
// code. No services: it names none because it needs none.
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string faceName: widgetConfig.face ?? Registry.defaultFaceOf("vtnc.square")
    readonly property string text: widgetConfig.text ?? "square"

    // Ver o comentario igual em widgets/clock/Clock.qml: o canal `options`
    // da decisao 3.4, entregue sem o module olhar o conteudo.
    readonly property var faceOptions: FaceSchema.resolveFaceOptions(
        Registry.optionSchemaOf("vtnc.square", root.faceName),
        FaceSchema.storedOptionsFor(root.widgetConfig, root.faceName))

    onFaceNameChanged: root.loadFace()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria a face no primeiro
    // quadro. Tudo o que o module publica (meta.js, `provides`) viaja assim.
    function loadFace() {
        faceLoader.setSource(Registry.resolvedFacePath("vtnc.square", root.faceName), {
            text: Qt.binding(() => root.text),
            options: Qt.binding(() => root.faceOptions)
        });
    }

    Loader {
        id: faceLoader
        anchors.fill: parent
        Component.onCompleted: root.loadFace()
    }
}
