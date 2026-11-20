import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core/grid.mjs" as Grid
import "../core"
import "../page"

// The island: a layer-shell surface anchored + offset, sized in cells, that
// wears one page at a time (decision 1e.1 — the island itself owns none of
// the lifecycle, the page does; the island only renders whichever page is
// currently assigned to it). An island can be mirrored across screens
// (decision 1c.4); each mirror is one of these, but they all read the same
// IslandState entry, since a `call` isn't tied to a monitor.
PanelWindow {
    id: root

    // Set by IslandManager from config.json.
    required property var islandConfig
    required property var configRef // the vtnc.Config singleton, to resolve the current page
    required property real cellPx // this screen's cell size in px (base * monitor factor)

    readonly property string islandName: islandConfig.name
    readonly property string idlePageName: islandConfig.page ?? ""
    readonly property string calledPageName: IslandState.calledPage(islandName)
    readonly property string currentPageName: calledPageName !== "" ? calledPageName : idlePageName

    readonly property var geometry: Grid.islandGeometry(islandConfig, cellPx)

    anchors.left: geometry.anchors.left
    anchors.right: geometry.anchors.right
    anchors.top: geometry.anchors.top
    anchors.bottom: geometry.anchors.bottom

    margins.left: geometry.margins.left
    margins.right: geometry.margins.right
    margins.top: geometry.margins.top
    margins.bottom: geometry.margins.bottom

    implicitWidth: geometry.width
    implicitHeight: geometry.height
    color: "transparent"

    WlrLayershell.layer: {
        switch (islandConfig.layer) {
        case "background": return WlrLayer.Background;
        case "bottom": return WlrLayer.Bottom;
        case "overlay": return WlrLayer.Overlay;
        default: return WlrLayer.Top;
        }
    }
    WlrLayershell.namespace: "vtnc-island-" + islandName

    Page {
        anchors.fill: parent
        pageConfig: configRef.page(root.currentPageName) ?? { grid: { cols: 1, rows: 1 }, widgets: [] }
        cellPx: root.cellPx
    }
}
