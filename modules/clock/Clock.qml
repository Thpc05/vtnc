import QtQuick
import "../../core"
import "../../services"
import "../../core/face-schema.mjs" as FaceSchema

// The module: vtnc.clock. Consumes the clock service (decision 5.2b) and
// wears one of its faces, chosen only by config (decision 3.1/3.5).
//
// 0.509: which faces exist is no longer written here. The module asks the
// registry for the QML path of the face it was asked to wear, and the
// registry derives that from each face's own meta.js — so adding a face
// to this module is adding a folder with a meta, and this file never
// changes. The one thing the module still owns is what it hands the face,
// and that is published in meta.js's `provides` (decision 3.5b).
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string faceName: widgetConfig.face ?? PluginRegistry.defaultFaceOf("vtnc.clock")
    readonly property string time: {
        const clock = ServiceRegistry.get("clock");
        return clock ? clock.time : "";
    }

    // O canal `options` (decisao 3.4): os valores que ESTE face declarou,
    // resolvidos contra os padroes dele e com os papeis de cor ja virados
    // cor. O module nao sabe o que sao essas opcoes nem as interpreta — ele
    // so entrega. Nao entra no `provides` do meta porque e canal do vtnc,
    // dado a toda face, e nao algo que este module inventou.
    readonly property var faceOptions: FaceSchema.resolveFaceOptions(
        PluginRegistry.optionSchemaOf("vtnc.clock", root.faceName),
        FaceSchema.storedOptionsFor(root.widgetConfig, root.faceName))

    Component.onCompleted: ServiceRegistry.acquire("clock")
    Component.onDestruction: ServiceRegistry.release("clock")

    onFaceNameChanged: root.loadFace()

    // Qt.binding, and not the plain value: setSource's initial properties
    // are assignments, so `time: root.time` would freeze the clock at
    // whatever second the face happened to load. Everything the module
    // publishes travels this way.
    function loadFace() {
        faceLoader.setSource(PluginRegistry.resolvedFaceUrl("vtnc.clock", root.faceName), {
            time: Qt.binding(() => root.time),
            options: Qt.binding(() => root.faceOptions)
        });
    }

    Loader {
        id: faceLoader
        anchors.fill: parent
        Component.onCompleted: root.loadFace()
    }
}
