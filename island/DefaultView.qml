// The main row is vtnc's IdleView (three widget sections, Iwidgets).
import QtQuick
import Quickshell
import qs.core
import qs.theme
import qs.services
import qs.components
import qs.compat
import qs.kit as K

Item {
    id: root
    focus: false

    required property ShellScreen screen
    // vtnc: island hover expansion (shows "hidden" widgets)
    property bool expanded: false
    // whole pixels only while the island rests (K.Kit.snap)
    property bool snap: true
    // widgets temporarily shown as "show" (media flash)
    property var flashedWidgets: []

    // State
    readonly property var activePlayer: MprisController.activePlayer
    property bool notchHovered: false
    property bool parentHoverActive: false

    readonly property bool expandedState: notchHovered || parentHoverActive || Visibilities.playerMenuOpen

    // Computed dimensions
    // vtnc: the row width comes from the widget sections (they animate their own width)
    readonly property int sidePadding: Store.island.padding
    readonly property real mainRowContentWidth: idleView.implicitWidth + 2 * sidePadding
    // vtnc: compact/expanded minimum sizes from the island settings; widgets can still make it grow
    readonly property real mainRowHeight: Math.max(expanded ? Store.island.heightExpanded : Store.island.height, idleView.implicitHeight)
    // animated like the widget slots, so switching compact ↔ expanded minimum width doesn't jump
    property real rowMinWidth: (expanded ? Store.island.minWidthExpanded : Store.island.minWidth) - 2 * sidePadding
    Behavior on rowMinWidth {
        enabled: K.Kit.anim.enabled
        K.Anim {
            type: K.Anim.BodySpatial
        }
    }
    // vtnc: the island's shape animates to the final width;
    // the widget slots inside animate on their own
    readonly property real finalRowMinWidth: (expanded ? Store.island.minWidthExpanded : Store.island.minWidth) - 2 * sidePadding

    implicitWidth: Math.round(idleView.targetWidth + 2 * sidePadding)
    implicitHeight: mainRowHeight

    Keys.onPressed: event => {
        if (expandedState && activePlayer) {
            if (event.key === Qt.Key_Space) {
                activePlayer.togglePlaying();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left && activePlayer.canSeek) {
                activePlayer.position = Math.max(0, activePlayer.position - 10);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right && activePlayer.canSeek) {
                activePlayer.position = Math.min(activePlayer.length, activePlayer.position + 10);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up && activePlayer.canGoPrevious) {
                activePlayer.previous();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down && activePlayer.canGoNext) {
                activePlayer.next();
                event.accepted = true;
            }
        }
    }

    Item {
        anchors.fill: parent

        // mainRow container
        Item {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width
            height: root.mainRowHeight
            z: 2

            IdleView {
                id: idleView
                anchors.centerIn: parent
                expanded: root.expanded
                flashed: root.flashedWidgets
                screen: root.screen
                minWidth: root.rowMinWidth
                finalMinWidth: root.finalRowMinWidth
                snap: root.snap
            }
        }
    }
}
