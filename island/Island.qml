import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core/grid.mjs" as Grid
import "../core/config-shape.mjs" as ConfigShape
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
    readonly property var exclusive: Grid.exclusiveZone(islandConfig, cellPx)

    // --- Autohide (0.505) -------------------------------------------------
    //
    // Hidden, the island is gone for real — no faixa fina, no sombra
    // (decision 11.2e) — which is also what frees the reservation the
    // 0.504 built (decision 2d.2). See island/README.md for the full
    // account of how hidden/revealed/the two animations are decided; the
    // short version is below.

    readonly property var resolvedAutohide: ConfigShape.resolveAutohide(configRef.data, islandConfig)
    readonly property var globalAutohide: configRef.data.autohide ?? ConfigShape.defaultAutohide()
    readonly property int triggerDistanceCells: globalAutohide.distance ?? 2
    readonly property var edgeInfo: Grid.nearestBorder(islandConfig)
    readonly property string animationKind: Grid.autohideAnimation(islandConfig, triggerDistanceCells)

    // Hyprland's own live state for this island's screen (AGENTS.md: a
    // read, never a dispatch, is in scope for 0.505). Quickshell.Hyprland
    // keeps these current from Hyprland's event socket — no polling here,
    // unlike the cursor position below, which Hyprland never pushes.
    readonly property var hyprMonitor: Hyprland.monitorFor(root.screen)
    readonly property var hyprWorkspace: hyprMonitor ? hyprMonitor.activeWorkspace : null
    readonly property bool hyprHasWindows: hyprWorkspace ? hyprWorkspace.toplevels.values.length > 0 : false
    readonly property bool hyprHasFullscreen: hyprWorkspace ? hyprWorkspace.hasFullscreen : false

    readonly property var monitorPx: hyprMonitor
        ? { x: hyprMonitor.x, y: hyprMonitor.y, width: hyprMonitor.width, height: hyprMonitor.height }
        : null
    readonly property var absoluteRect: monitorPx ? Grid.islandAbsoluteRect(islandConfig, cellPx, monitorPx) : null
    readonly property real hoverBandPx: triggerDistanceCells * cellPx

    // The two ways a hidden island comes back (decision 11.2d): the mouse
    // at its nearest border, or already over its own body — so it doesn't
    // flicker shut the instant the mouse leaves the border strip to reach
    // the content it just revealed, an implementation detail the graph
    // doesn't pin down — or a call landing on it from some other service,
    // which is just the existing idle/called distinction (core/IslandState)
    // read again: nothing new had to be built for that half of 11.2d.
    readonly property bool revealedByHover: monitorPx
        ? (Grid.cursorNearBorder(HoverCursor.pos, edgeInfo.edge, monitorPx, hoverBandPx)
            || (absoluteRect !== null && Grid.cursorOverRect(HoverCursor.pos, absoluteRect)))
        : false
    // A call to the island's own idle page counts as "the call ended"
    // (decision 1e.2: idle is the fallback the call stack rests at) — there
    // is no separate "end the call" verb yet (core/IslandState.clearCall
    // exists but nothing calls it; Esc/click-outside is keybind/lifecycle
    // work, out of 0.505's scope), so this reuses the one mechanism that
    // already exists: calling the idle page back.
    readonly property bool revealedByCall: calledPageName !== "" && calledPageName !== idlePageName

    readonly property bool modeWantsHide: Grid.modeSaysHide(resolvedAutohide.mode, {
        hasWindows: hyprHasWindows,
        hasFullscreen: hyprHasFullscreen,
    })
    readonly property bool shouldAutoHide: resolvedAutohide.enabled && modeWantsHide
    readonly property bool hidden: shouldAutoHide && !revealedByHover && !revealedByCall

    // The reservation is released only once the hide animation has had
    // time to finish — so a window doesn't grow into a spot the island is
    // still visually sliding/shrinking through — but restored the instant
    // a reveal starts, so windows make room right away rather than after
    // the island has already reappeared on top of them.
    property bool settledHidden: false
    Timer {
        id: settleTimer
        interval: Math.max(root.globalAutohide.fade ?? 150, root.globalAutohide.slideSpeed ?? 150)
        // Bound, not toggled from a change handler: an island can be
        // `hidden` from the very moment it's created (autohide on + mode
        // always, say), and a property change handler never fires for a
        // binding's first evaluation — only `running`'s own binding sees
        // that initial value and starts the timer correctly either way.
        running: root.hidden
        onTriggered: root.settledHidden = true
    }
    onHiddenChanged: if (!hidden) root.settledHidden = false

    readonly property real effectiveExclusiveZonePx: (hidden && settledHidden) ? 0 : exclusive.px

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

    // The reservation has to be asked for explicitly (the risk recorded in
    // the graph for 0.504): PanelWindow's automatic exclusionMode only
    // reserves when the surface spans its whole anchored edge, which a
    // corner-anchored island like a dock never does. Forcing Normal and
    // setting exclusiveZone ourselves — from Grid.exclusiveZone, gated by
    // effectiveExclusiveZonePx above while autohide has it hidden — means
    // an island that shouldn't reserve anything simply asks for zero,
    // rather than leaving the decision to the surface's own geometry.
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.exclusiveZone: root.effectiveExclusiveZonePx

    // Hidden: no input anywhere on the surface, so a click meant for
    // whatever is behind it reaches that window instead of this one —
    // wlr-layer-shell has no "hover but let the click through" region, so
    // an empty mask (rather than, say, unmapping the surface, which would
    // also have to drop and remake it on every reveal) is how this avoids
    // stealing a click without a real pointer-injection tool to prove it
    // against (see tests/README.md's note on ydotool/virtual-pointer).
    mask: root.hidden ? root.emptyMask : null
    property Region emptyMask: Region { x: 0; y: 0; width: 0; height: 0 }

    Item {
        id: contentRoot
        anchors.fill: parent

        readonly property string edge: root.edgeInfo.edge

        x: (root.hidden && root.animationKind === "slide")
            ? (edge === "left" ? -width : edge === "right" ? width : 0)
            : 0
        y: (root.hidden && root.animationKind === "slide")
            ? (edge === "top" ? -height : edge === "bottom" ? height : 0)
            : 0
        scale: (root.hidden && root.animationKind === "shrink") ? 0 : 1
        opacity: root.hidden ? 0 : 1

        transformOrigin: {
            switch (edge) {
            case "top": return Item.Top;
            case "bottom": return Item.Bottom;
            case "left": return Item.Left;
            case "right": return Item.Right;
            default: return Item.Center;
            }
        }

        Behavior on x { NumberAnimation { duration: root.globalAutohide.slideSpeed ?? 150 } }
        Behavior on y { NumberAnimation { duration: root.globalAutohide.slideSpeed ?? 150 } }
        // shrinkSize ("o tamanho ao longo da animação, não um estado final
        // visível", decision 11.2e) always ends at scale 0 — nothing rests
        // visible — so it's read here as how far the InBack easing
        // overshoots on the way there, not as a resting size. That specific
        // mapping (cells straight into the easing curve's unitless
        // overshoot factor) is this implementation's own call, not
        // something the graph pins down — see island/README.md.
        Behavior on scale {
            NumberAnimation {
                duration: root.globalAutohide.fade ?? 150
                easing.type: root.animationKind === "shrink" ? Easing.InBack : Easing.Linear
                easing.overshoot: Math.max(0, root.globalAutohide.shrinkSize ?? 1)
            }
        }
        Behavior on opacity { NumberAnimation { duration: root.globalAutohide.fade ?? 150 } }

        Page {
            anchors.fill: parent
            pageConfig: configRef.page(root.currentPageName) ?? { grid: { cols: 1, rows: 1 }, widgets: [] }
            cellPx: root.cellPx
        }
    }
}
