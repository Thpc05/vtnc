import QtQuick
import "../../services"
import "../../core/widget-registry.mjs" as Registry

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

    Component.onCompleted: ServiceRegistry.acquire("clock")
    Component.onDestruction: ServiceRegistry.release("clock")

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, and not the plain value: setSource's initial properties
    // are assignments, so `time: root.time` would freeze the clock at
    // whatever second the style happened to load. Everything the type
    // publishes travels this way.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.clock", root.styleName), {
            time: Qt.binding(() => root.time)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
