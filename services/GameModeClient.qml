pragma Singleton

import QtQuick
import Quickshell

// Compat GameModeClient on top of vtnc's Controls.
Singleton {
    readonly property bool toggled: Controls.gameMode

    function toggle() {
        Controls.toggleGameMode();
    }
}
