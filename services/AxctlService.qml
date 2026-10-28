pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Compat AxctlService (compositor state), backed by Quickshell.Hyprland. Only what transplanted code reads.
Singleton {
    id: root

    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var clients: Hyprland.toplevels

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen);
    }
}
