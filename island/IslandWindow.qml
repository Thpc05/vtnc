import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K

// One full-screen, click-through overlay per screen that hosts the island.
// Input region = island bounds. While an app is open (on any screen) it becomes the
// whole screen on every monitor, so clicking anywhere outside the island closes the app.
PanelWindow {
    id: window

    // the app's page is shown here (not covered by a transient)
    readonly property bool appShown: island.showingApp
    readonly property bool anyAppOpen: Runtime.activeApp !== ""
    // full-screen input while an app or a popup grab is active; a transient (OSD, notification)
    // on this screen takes only the island, even over an app: no keyboard, no backdrop close
    readonly property bool needsFullScreenInput: (anyAppOpen && !island.transientActive) || FocusGrabManager.hasActiveGrab

    // the screen frame (Store.frame, caelestia's) and the rounded screen corners, independent;
    // both collapse while a window is fullscreen
    readonly property bool frameOn: Store.frame.enabled
    readonly property bool fullscreen: Hypr.hasFullscreen(screen)
    property real frameThickness: frameOn && !fullscreen ? Math.max(0, Store.frame.thickness) : 0
    property real frameRounding: Store.frame.roundCorners && !fullscreen ? Math.max(0, Store.frame.rounding) : 0
    Behavior on frameThickness {
        K.Anim {
            type: K.Anim.BodySpatial
        }
    }
    Behavior on frameRounding {
        K.Anim {
            type: K.Anim.BodySpatial
        }
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "vtnc"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: appShown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // hidden island: only the activation strip takes input (hover reveals it)
    mask: Region {
        item: window.needsFullScreenInput ? backdrop : (island.concealed ? activationStrip : island)
    }

    // auto-hide activation strip at the top edge, island.autohide_px tall
    Item {
        id: activationStrip
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: island.width + 20
        height: Math.max(1, Store.island.autohide_px)

        HoverHandler {
            onHoveredChanged: island.stripHovered = hovered
        }
    }

    // `qs -c vtnc ipc call shell perf on`: this window's frame rate in the log
    Loader {
        active: Runtime.perf
        sourceComponent: PerfMeter {
            name: window.screen?.name ?? ""
        }
    }

    // caffeine (the inhibitor needs a visible window)
    IdleInhibitor {
        window: window
        enabled: Controls.caffeine
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: window.needsFullScreenInput
        // a click outside closes the topmost popup grab first (FocusGrabManager), then the app
        onClicked: mouse => {
            // clicks on the island's own empty areas (e.g. an app's background) fall through
            // to this backdrop: only clicks really outside the island close things
            if (island.contains(island.mapFromItem(backdrop, mouse.x, mouse.y)))
                return;
            if (FocusGrabManager.hasActiveGrab)
                FocusGrabManager.clearTopGrab();
            else
                Runtime.closeApp();
        }
    }

    // The shell's surface, as caelestia's drawers: the frame and the island's body in ONE layer, one
    // liquid shape under one shadow (stage 8: K.BlobSurface, our SDF shader; the body flows into the
    // frame, or the screen's edge, with the notch's flares), transparency applied to the whole (the
    // layer's opacity = Appearance → Transparency's base). The island's content stays outside any
    // layer (crisp text while it morphs).
    Item {
        id: surface
        anchors.fill: parent
        opacity: Colors.transparency.enabled ? Colors.transparency.base : 1
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colors.shadow, 0.7)
        }

        K.BlobSurface {
            anchors.fill: parent
            color: Colors.background
            frameColor: Colors.frame
            frameThickness: window.frameThickness
            frameRounding: window.frameRounding
            blobs: [islandBlob]
        }
    }

    // the island's body in the window's coordinates, with the island's transforms (auto-hide slide,
    // hop, width scale about its centre). Notch: square top corners reaching up into the edge, merged
    // with the flares. Island (floating): its own radius all round, merging into the edge only as it
    // nears it (the hop, the hide: the merge radius grows as the gap closes)
    K.Blob {
        id: islandBlob

        readonly property real scale: island.bodyXScale
        readonly property real originX: island.x + island.width / 2
        readonly property real centreX: originX + (island.x + island.bodyLeft + island.bodyWidth / 2 - originX) * scale
        readonly property real top: island.y + island.bodyTop + island.slideY + island.hopY
        readonly property bool notch: island.notchStyle
        // the floating island's gap to the edge (its margin at rest)
        readonly property real gap: Store.island.margin + island.slideY + island.hopY

        visible: island.visible && island.opacity > 0.01
        x: centreX - island.bodyWidth / 2 * scale
        width: island.bodyWidth * scale
        y: notch ? -64 : top
        height: notch ? top + island.bodyHeight + 64 : island.bodyHeight
        topLeftRadius: notch ? 0 : island.bodyRadius
        topRightRadius: notch ? 0 : island.bodyRadius
        bottomLeftRadius: island.bodyRadius
        bottomRightRadius: island.bodyRadius
        smoothing: notch ? island.flare : Store.island.margin > 0 ? island.flareSize * Math.max(0, Math.min(1, 1 - gap / Store.island.margin)) : island.flareSize
    }

    Island {
        id: island
        frameTop: window.frameThickness
        screen: window.screen
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        // exact centre (not rounded to a pixel): the content inside keeps a constant screen
        // position while the width animates by fractions. No layer here: the shadow is on the
        // body's backgrounds only (Island.qml bodyLayer), so the text isn't drawn into a texture
        anchors.alignWhenCentered: false
        width: implicitWidth
        height: implicitHeight
        focus: true
    }
}
