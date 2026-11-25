import QtQuick
import "../../core/config-shape.mjs" as ConfigShape
import "../../core"

// The module: vtnc.island-editor. Reads one island's live state straight from
// core/Config.qml (so it reflects any change, from anywhere, immediately)
// and writes nothing itself — every edit becomes a CliRunner.run() call to
// the real cli/vtnc binary (decision 6.3's exception). That boundary is
// what acceptance criterion 4 of 0.503 checks: make cli/vtnc
// non-executable, and nothing from here should still reach config.json.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string faceName: widgetConfig.face ?? PluginRegistry.defaultFaceOf("vtnc.island-editor")
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

    onFaceNameChanged: root.loadFace()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria a face no primeiro
    // quadro. Tudo o que o module publica (meta.js, `provides`) viaja assim.
    function loadFace() {
        faceLoader.setSource(PluginRegistry.resolvedFaceUrl("vtnc.island-editor", root.faceName), {
            islandName: Qt.binding(() => root.islandName),
            anchor: Qt.binding(() => root.anchor),
            offset: Qt.binding(() => root.offset),
            size: Qt.binding(() => root.size),
            gap: Qt.binding(() => root.gap),
            islandLayer: Qt.binding(() => root.islandLayer),
            pageName: Qt.binding(() => root.pageName),
            pageNames: Qt.binding(() => root.pageNames),
            edges: Qt.binding(() => root.edges),
            layers: Qt.binding(() => root.layers),
            autohideModes: Qt.binding(() => root.autohideModes),
            autohide: Qt.binding(() => root.autohide),
            autohideMode: Qt.binding(() => root.autohideMode),
            setAnchorEdge: Qt.binding(() => root.setAnchorEdge),
            nudgeOffset: Qt.binding(() => root.nudgeOffset),
            nudgeSize: Qt.binding(() => root.nudgeSize),
            nudgeGap: Qt.binding(() => root.nudgeGap),
            setLayer: Qt.binding(() => root.setLayer),
            setPage: Qt.binding(() => root.setPage),
            setAutohide: Qt.binding(() => root.setAutohide),
            setAutohideMode: Qt.binding(() => root.setAutohideMode)
        });
    }

    Loader {
        id: faceLoader
        anchors.fill: parent
        Component.onCompleted: root.loadFace()
    }
}
