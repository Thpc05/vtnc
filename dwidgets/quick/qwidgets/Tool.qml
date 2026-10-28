import QtQuick
import qs.services
import qs.core
import qs.theme
import ".."
import "../../../apps/tools/actions.js" as ToolActions

// One screen tool (apps/tools/actions.js: `tool` is its id), run like the Tools app does
// (core/Actions.qml). A record one is on while recording, and its click then stops it.
Qwidget {
    id: root

    property string tool
    readonly property var info: ToolActions.find(tool) ?? ({})
    readonly property bool record: ToolActions.isRecord(tool)

    title: info.short ?? info.label ?? ""
    symbol: Icons[info.icon] ?? ""
    icon: Icons[info.icon] ?? ""
    active: record && ScreenTools.recording
    status: active ? ScreenTools.elapsedText : ""

    function toggle() {
        Actions.runTool(root.record && ScreenTools.recording ? "stop" : root.tool);
    }
}
