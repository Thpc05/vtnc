import QtQuick
import "../../core"

// The module: vtnc.autohide-settings. The one global autohide knob the
// Settings Islands page needs, besides what each island's own
// vtnc.island-editor already shows (decision 12.4 — trigger distance is
// global, not per-island). Reads core/Config.qml directly and writes
// nothing itself — every edit becomes a CliRunner.run() call, same
// boundary as vtnc.island-editor (decision 6.3's exception).
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string faceName: widgetConfig.face ?? PluginRegistry.defaultFaceOf("vtnc.autohide-settings")
    readonly property var autohide: Config.data.autohide ?? ({ distance: 2 })
    readonly property int distance: autohide.distance ?? 2

    function nudgeDistance(delta) {
        CliRunner.run(["autohide", "set", "distance", String(Math.max(0, distance + delta))]);
    }

    onFaceNameChanged: root.loadFace()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria a face no primeiro
    // quadro. Tudo o que o module publica (meta.js, `provides`) viaja assim.
    function loadFace() {
        faceLoader.setSource(PluginRegistry.resolvedFaceUrl("vtnc.autohide-settings", root.faceName), {
            distance: Qt.binding(() => root.distance),
            nudgeDistance: Qt.binding(() => root.nudgeDistance)
        });
    }

    Loader {
        id: faceLoader
        anchors.fill: parent
        Component.onCompleted: root.loadFace()
    }
}
