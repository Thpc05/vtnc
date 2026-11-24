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
// (decision 1c.4); each mirror is one of these, and they all read the same
// IslandState call stack — a `call` isn't tied to a monitor — but only the
// mirror whose monitor was focused at call time actually wears it
// (decisions 1e.3/1e.3b); the others keep showing idle.
PanelWindow {
    id: root

    // Set by IslandManager from config.json.
    required property var islandConfig
    required property var configRef // the vtnc.Config singleton, to resolve the current page
    required property real cellPx // this screen's cell size in px (base * monitor factor)

    readonly property string islandName: islandConfig.name
    readonly property string idlePageName: islandConfig.page ?? ""
    readonly property string calledPageName: IslandState.calledPage(islandName)

    // --- Lifecycle (0.506) -------------------------------------------------
    //
    // A called page appears only on the monitor that was focused at the
    // instant it was called (decision 1e.3b, superseding this step's first
    // attempt at 1e.3): IslandState.call captured that monitor's name once,
    // in shell.qml's IpcHandler — this just compares against it, it never
    // reads Hyprland.focusedMonitor live. Measuring the live-comparison
    // version showed the called page dragging itself to a different mirror
    // the instant focus moved there, which decision 1e.3b settled as wrong
    // — a launcher called on purpose should stay where it was called.
    readonly property string monitorName: hyprMonitor ? hyprMonitor.name : (root.screen ? root.screen.name : "")
    readonly property var calledMonitorName: IslandState.calledMonitor(islandName)
    readonly property bool showingCalled: calledPageName !== "" && calledMonitorName === monitorName
    readonly property string currentPageName: showingCalled ? calledPageName : idlePageName

    // Observability for criterion 3 — which page each mirror draws, read
    // back through `vtnc island <name> get`'s `mirrors` field without
    // comparing a pixel.
    onCurrentPageNameChanged: IslandState.setMirrorPage(islandName, monitorName, currentPageName)
    Component.onCompleted: IslandState.setMirrorPage(islandName, monitorName, currentPageName)

    // The called page's own declared lifecycle (decisions 1e.0/1e.1): a
    // page is "called" by default, or declares "popup"/"lock". Idle has no
    // lifecycle of its own to read — it's just the absence of a call.
    readonly property string currentLifecycle: showingCalled
        ? ConfigShape.pageLifecycle(configRef.page(calledPageName))
        : "idle"
    readonly property bool isPopup: currentLifecycle === "popup"
    readonly property bool isLock: currentLifecycle === "lock"
    readonly property bool pageNeedsKeyboard: showingCalled && ConfigShape.pageNeedsKeyboard(configRef.page(calledPageName))

    // O estado empty (decisao 14.3): a page que a island veste pode nao
    // existir - foi apagada no editor de Pages, ou o nome nunca existiu.
    // Nesse caso a island nao some nem fica do tamanho cheio mostrando
    // nada: ela encolhe para a bolinha de 2x2, e a reserva de espaco
    // encolhe junto, porque as duas saem do mesmo retangulo.
    readonly property bool hasPage: !!configRef.page(currentPageName)
    readonly property var effectiveIslandConfig: hasPage
        ? islandConfig
        : Grid.emptyStateIsland(islandConfig)

    readonly property var geometry: Grid.islandGeometry(effectiveIslandConfig, cellPx)
    readonly property var exclusive: Grid.exclusiveZone(effectiveIslandConfig, cellPx)

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
    // 0.506 superseded the 0.505 slang here: a real call stack and a real
    // `end` exist now (core/IslandState.qml), and revealing-by-call only
    // applies to the mirror actually showing the called page — the focused
    // one (decision 1e.3).
    readonly property bool revealedByCall: showingCalled

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

    // --- Esc (0.506, criterion 4) -------------------------------------------
    //
    // Click-outside is OUT of the contract for now (decision 1e.4b): a
    // wlr-layer-shell surface can't see a click that lands outside it, and
    // the only direct way to fake it — a fullscreen transparent catcher —
    // steals every click behind it from whoever it belongs to, the same
    // family of problem as the 0.505 hover band. An earlier version of this
    // file reacted to Quickshell.Hyprland's activeToplevel changing, which
    // covers clicking a real window but not clicking empty desktop space or
    // another vtnc surface — half a behavior the user would learn to trust
    // and then have it fail silently, which is worse than no behavior at
    // all (decision 1e.4b's own rationale). Taken back out rather than kept
    // as a partial approximation; see oq-clique-fora-mecanismo in the graph
    // for anyone picking this up again, and the record kept below.
    //
    // Esc needs keyboard focus on this surface, and grabbing it outright is
    // the difference between closing a popup and hijacking Theo's keyboard
    // (decision 1e.5): only a page that declares needsKeyboard gets
    // Exclusive; every other called/popup page gets OnDemand — eligible for
    // focus once the user clicks into it, never forced. Idle never asks for
    // focus at all. The lock exception (1e.4) doesn't need a separate
    // branch here: a lock page simply never shows Esc's handler armed
    // below, so there's nothing for a stray Escape to do.
    WlrLayershell.keyboardFocus: root.showingCalled
        ? (root.pageNeedsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    // The popup lifecycle's own auto-dismiss (decision 1e.0): restarted on
    // every new popup push, not just started once, since two popups called
    // back to back never toggle `isPopup` itself (it stays true both
    // times) — only calledPageNameChanged tells them apart.
    Timer {
        id: popupTimer
        interval: ConfigShape.pagePopupTimeout(configRef.page(root.calledPageName))
        running: root.isPopup
        onTriggered: IslandState.end(root.islandName)
    }
    onCalledPageNameChanged: if (isPopup) popupTimer.restart()

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
            visible: root.hasPage
            pageConfig: configRef.page(root.currentPageName) ?? { grid: { cols: 1, rows: 1 }, widgets: [] }
            cellPx: root.cellPx
        }

        // A bolinha do estado empty (decisao 14.3). Serve tanto para a page
        // apagada quanto para a island recem-criada que ainda nao veste
        // nada: em vez de uma superficie invisivel, que nao da para clicar
        // nem para achar, fica uma marca de 2x2 celulas na tela.
        Rectangle {
            anchors.fill: parent
            visible: !root.hasPage
            radius: Math.min(width, height) / 2
            color: "#3a3a3a"
            border.color: "#6a6a6a"
            border.width: 1
        }

        // Esc (decision 1e.4): only armed while showing a called/popup page
        // that isn't lock — this Item never consumes a mouse click (it's
        // not a MouseArea), it only ever reacts to a key, and only once it
        // actually has focus (WlrKeyboardFocus above decides whether that
        // happens on its own or waits for a click into the surface first).
        Item {
            anchors.fill: parent
            focus: root.showingCalled && !root.isLock
            Keys.onEscapePressed: IslandState.end(root.islandName)
        }

        // The popup lifecycle's other way out (decision 1e.0): the x in
        // the corner, alongside the timeout above. Deliberately minimal —
        // no chrome at all for called/lock, which never show this.
        Rectangle {
            visible: root.isPopup
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 16
            height: 16
            radius: 8
            color: "#80000000"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: IslandState.end(root.islandName)
            }
        }
    }
}
