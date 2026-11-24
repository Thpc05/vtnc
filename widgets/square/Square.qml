import QtQuick
import "../../core/widget-registry.mjs" as Registry
import "../../core/style-schema.mjs" as StyleSchema

// The type: vtnc.square. A dumb widget — a square with text — that exists
// to prove the type/style split (decision 3.1/3.5) with the least possible
// code. No services: it names none because it needs none.
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? Registry.defaultStyleOf("vtnc.square")
    readonly property string text: widgetConfig.text ?? "square"

    // Ver o comentario igual em widgets/clock/Clock.qml: o canal `options`
    // da decisao 3.4, entregue sem o type olhar o conteudo.
    readonly property var styleOptions: StyleSchema.resolveStyleOptions(
        Registry.optionSchemaOf("vtnc.square", root.styleName),
        StyleSchema.storedOptionsFor(root.widgetConfig, root.styleName))

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria o style no primeiro
    // quadro. Tudo o que o type publica (meta.js, `provides`) viaja assim.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.square", root.styleName), {
            text: Qt.binding(() => root.text),
            options: Qt.binding(() => root.styleOptions)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
