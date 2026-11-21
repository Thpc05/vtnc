import QtQuick
import "../../core"
import "./styles/panel"

// The type: vtnc.autohide-settings. The one global autohide knob the
// Settings Islands page needs, besides what each island's own
// vtnc.island-editor already shows (decision 12.4 — trigger distance is
// global, not per-island). Reads core/Config.qml directly and writes
// nothing itself — every edit becomes a CliRunner.run() call, same
// boundary as vtnc.island-editor (decision 6.3's exception).
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "panel"
    readonly property var autohide: Config.data.autohide ?? ({ distance: 2 })
    readonly property int distance: autohide.distance ?? 2

    function nudgeDistance(delta) {
        CliRunner.run(["autohide", "set", "distance", String(Math.max(0, distance + delta))]);
    }

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.styleName) {
            case "panel": return panelStyle;
            default: return panelStyle;
            }
        }
    }

    Component {
        id: panelStyle
        Panel {
            distance: root.distance
            nudgeDistance: root.nudgeDistance
        }
    }
}
