pragma Singleton

import QtQuick
import Quickshell

// Compat CaffeineClient on top of vtnc's Controls.
Singleton {
    readonly property bool inhibit: Controls.caffeine

    function toggle() {
        Controls.toggleCaffeine();
    }
}
