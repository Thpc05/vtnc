import QtQuick
import "../../services"
import "../../core/widget-registry.mjs" as Registry
import "../../core/style-schema.mjs" as StyleSchema

// The type: vtnc.clock. Consumes the clock service (decision 5.2b) and
// wears one of its styles, chosen only by config (decision 3.1/3.5).
//
// 0.509: which styles exist is no longer written here. The type asks the
// registry for the QML path of the style it was asked to wear, and the
// registry derives that from each style's own meta.js — so adding a style
// to this type is adding a folder with a meta, and this file never
// changes. The one thing the type still owns is what it hands the style,
// and that is published in meta.js's `provides` (decision 3.5b).
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? Registry.defaultStyleOf("vtnc.clock")
    readonly property string time: {
        const clock = ServiceRegistry.get("clock");
        return clock ? clock.time : "";
    }

    // O canal `options` (decisao 3.4): os valores que ESTE style declarou,
    // resolvidos contra os padroes dele e com os papeis de cor ja virados
    // cor. O type nao sabe o que sao essas opcoes nem as interpreta — ele
    // so entrega. Nao entra no `provides` do meta porque e canal do vtnc,
    // dado a todo style, e nao algo que este type inventou.
    readonly property var styleOptions: StyleSchema.resolveStyleOptions(
        Registry.optionSchemaOf("vtnc.clock", root.styleName),
        StyleSchema.storedOptionsFor(root.widgetConfig, root.styleName))

    Component.onCompleted: ServiceRegistry.acquire("clock")
    Component.onDestruction: ServiceRegistry.release("clock")

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, and not the plain value: setSource's initial properties
    // are assignments, so `time: root.time` would freeze the clock at
    // whatever second the style happened to load. Everything the type
    // publishes travels this way.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.clock", root.styleName), {
            time: Qt.binding(() => root.time),
            options: Qt.binding(() => root.styleOptions)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
