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
// mirror on the focused monitor actually wears it (decision 1e.3); the
// others keep showing idle.
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
    // A called page appears only on the focused monitor; every other mirror
    // keeps wearing whatever it had (decision 1e.3). The 0.505 autohide
    // window-mode already reads "each monitor's own workspace, decided by
    // that mirror alone" — this follows the same shape: a live, reactive
    // comparison against Hyprland.focusedMonitor, not something fixed at
    // call-time. A consequence worth flagging: if focus moves to a
    // different monitor while a call is still active, rendering follows
    // focus live — the called page would appear to "jump" mirrors. The
    // graph doesn't say which of the two readings it means; this is the
    // simpler one, and the one "cada espelho decide por si" reads most
    // naturally as.
    readonly property string monitorName: hyprMonitor ? hyprMonitor.name : (root.screen ? root.screen.name : "")
    readonly property bool isFocusedMonitor: Hyprland.focusedMonitor !== null
        && hyprMonitor !== null
        && Hyprland.focusedMonitor.name === hyprMonitor.name
    readonly property bool showingCalled: calledPageName !== "" && isFocusedMonitor
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

    // --- Esc and click-outside (0.506, criterion 4) ------------------------
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

    // Click-outside has no clean answer in wlr-layer-shell — the same
    // family of problem as 0.505's hover band: there is no "receives a
    // click outside me" region, only "receives this click" or "doesn't",
    // and a fullscreen transparent catcher would steal every click behind
    // it from whoever it belongs to, which this step explicitly rules out.
    // What Hyprland *does* expose, read-only, is which toplevel is active
    // (Quickshell.Hyprland's activeToplevel) — clicking a real window
    // changes it, even while this surface holds exclusive keyboard focus,
    // because Hyprland's active-toplevel tracking is independent of
    // layer-shell keyboard grabs. Ending the call when that changes covers
    // the overwhelmingly common case (clicking some other real window) but
    // NOT clicking empty desktop space or another one of vtnc's own
    // layer-shell surfaces — neither is a toplevel, neither fires this
    // event. That gap is real and unclosed by this step; see
    // island/README.md.
    //
    // `clickOutsideArmed` exists because the moment a surface first grabs
    // keyboard focus is exactly the kind of focus churn that could fire
    // activeToplevelChanged on its own — arming it 50ms after showingCalled
    // turns true, rather than the instant it does, avoids a call closing
    // itself before anyone had a chance to see it. This mirrors the settle
    // delay autohide already uses for the opposite reason (hiding, not
    // showing) a few lines up.
    property bool clickOutsideArmed: false
    Timer {
        id: armClickOutside
        interval: 50
        running: root.showingCalled && !root.isLock
        onTriggered: root.clickOutsideArmed = true
    }
    onShowingCalledChanged: if (!showingCalled) root.clickOutsideArmed = false

    Connections {
        target: Hyprland
        enabled: root.showingCalled && !root.isLock && root.clickOutsideArmed
        function onActiveToplevelChanged() {
            IslandState.end(root.islandName);
        }
    }

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
            pageConfig: configRef.page(root.currentPageName) ?? { grid: { cols: 1, rows: 1 }, widgets: [] }
            cellPx: root.cellPx
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
