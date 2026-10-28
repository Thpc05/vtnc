import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// Invisible window that reserves the island's idle height as an exclusive zone
// (so tiled windows don't go under it). Enabled by Store.island.reserveSpace.
PanelWindow {
    color: "transparent"
    WlrLayershell.namespace: "vtnc:reserve"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 1
    // auto-hide levels 2 (windows) and 3 (always) hide the island over windows: nothing to reserve
    readonly property bool autohidden: Store.island.autohide && Store.island.autohide_nv >= 2
    exclusiveZone: autohidden ? 0 : Store.island.height + (Store.island.style === "notch" ? 0 : Store.island.margin)
}
