import QtQuick
import "../../widgets/island-editor"

// 0.503 acceptance criterion 4: Settings never writes configuration on its
// own. This drives the real vtnc.island-editor type exactly the way a
// click on its Panel style would — through its public setXxx/nudgeXxx
// functions, never touching core/Config.qml directly — and leaves checking
// the result (config.json, with cli/vtnc made non-executable by the driver
// script) to tests/cli/settings-write-boundary.sh. Needs no compositor:
// the type is a plain Item, and core/CliRunner.qml only needs
// Quickshell.shellDir, which `qs -p` provides without a Wayland backend.
Item {
    IslandEditor {
        id: editor
        widgetConfig: ({ islandName: "bar" })
    }

    Timer {
        running: true
        interval: 300
        onTriggered: {
            editor.setLayer("overlay");
            exitTimer.start();
        }
    }

    Timer {
        id: exitTimer
        interval: 800
        onTriggered: Qt.exit(0)
    }
}
