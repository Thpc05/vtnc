pragma Singleton

import QtQuick
import Quickshell

// Compat NightLightClient on top of vtnc's Controls.
Singleton {
    readonly property bool active: Controls.nightLight

    function toggle() {
        Controls.toggleNightLight();
    }
}
