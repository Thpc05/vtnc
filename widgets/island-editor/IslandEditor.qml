import QtQuick
import "../../core/config-shape.mjs" as ConfigShape
import "../../core"
import "./styles/panel"

// The type: vtnc.island-editor. Reads one island's live state straight from
// core/Config.qml (so it reflects any change, from anywhere, immediately)
// and writes nothing itself — every edit becomes a CliRunner.run() call to
// the real cli/vtnc binary (decision 6.3's exception). That boundary is
// what acceptance criterion 4 of 0.503 checks: make cli/vtnc
// non-executable, and nothing from here should still reach config.json.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "panel"
    readonly property string islandName: widgetConfig.islandName ?? ""
    readonly property var island: Config.island(islandName) ?? {}

    readonly property var anchor: island.anchor ?? {}
    readonly property var offset: island.offset ?? { x: 0, y: 0 }
    readonly property var size: island.size ?? { w: 1, h: 1 }
    readonly property int gap: island.gap ?? 0
    readonly property string islandLayer: island.layer ?? "top"
    readonly property string pageName: island.page ?? ""
    readonly property var pageNames: Object.keys(Config.data.pages ?? {})

    // 0.505: autohide/autohideMode are optional per-island overrides
    // (decision 11.2c) — resolved the same way Island.qml resolves them,
    // so the toggle shown here always reflects what's actually in effect,
    // whether this island set its own or is just inheriting the global.
    readonly property var resolvedAutohide: ConfigShape.resolveAutohide(Config.data, island)
    readonly property bool autohide: resolvedAutohide.enabled
    readonly property string autohideMode: resolvedAutohide.mode

    readonly property var edges: ["top", "bottom", "left", "right"]
    readonly property var layers: ["background", "bottom", "top", "overlay"]
    readonly property var autohideModes: ["always", "window", "fullscreen"]

    function setAnchorEdge(edge, value) {
        const next = { top: !!anchor.top, bottom: !!anchor.bottom, left: !!anchor.left, right: !!anchor.right };
        next[edge] = value;
        CliRunner.run(["island", islandName, "set", "anchor", JSON.stringify(next)]);
    }

    function nudgeOffset(axis, delta) {
        const next = { x: offset.x ?? 0, y: offset.y ?? 0 };
        next[axis] = (next[axis] ?? 0) + delta;
        CliRunner.run(["island", islandName, "set", "offset", JSON.stringify(next)]);
    }

    function nudgeSize(axis, delta) {
        const next = { w: size.w ?? 1, h: size.h ?? 1 };
        next[axis] = Math.max(1, (next[axis] ?? 1) + delta);
        CliRunner.run(["island", islandName, "set", "size", JSON.stringify(next)]);
    }

    function nudgeGap(delta) {
        CliRunner.run(["island", islandName, "set", "gap", String(Math.max(0, gap + delta))]);
    }

    function setLayer(value) {
        CliRunner.run(["island", islandName, "set", "layer", value]);
    }

    function setAutohide(value) {
        CliRunner.run(["island", islandName, "set", "autohide", value ? "true" : "false"]);
    }

    function setAutohideMode(value) {
        CliRunner.run(["island", islandName, "set", "autohideMode", value]);
    }

    function setPage(value) {
        CliRunner.run(["island", islandName, "set", "page", value]);
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
            islandName: root.islandName
            anchor: root.anchor
            offset: root.offset
            size: root.size
            gap: root.gap
            islandLayer: root.islandLayer
            pageName: root.pageName
            pageNames: root.pageNames
            edges: root.edges
            layers: root.layers
            autohideModes: root.autohideModes
            autohide: root.autohide
            autohideMode: root.autohideMode
            setAnchorEdge: root.setAnchorEdge
            nudgeOffset: root.nudgeOffset
            nudgeSize: root.nudgeSize
            nudgeGap: root.nudgeGap
            setLayer: root.setLayer
            setPage: root.setPage
            setAutohide: root.setAutohide
            setAutohideMode: root.setAutohideMode
        }
    }
}
