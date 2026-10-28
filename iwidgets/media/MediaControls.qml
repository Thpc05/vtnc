import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.theme
import qs.services
import qs.components
import qs.kit as K

// The media Iwidget's controls (island.media.<mode>.controls, 2026-10-15: an option of every style, was
// the "Controls" style): after the style's look, previous · next · shuffle / repeat · the player's icon,
// in the style's colours (`ink`, `activeInk` for shuffle / repeat on, `offInk` off; the player's hover is a
// primary state layer). The art / disc / title
// still plays and pauses. The player's icon cycles the players; a right click opens the player picker
// (Automatic or a pinned app, as the dashboard's).
Row {
    id: root

    // (a property named onX reads as a signal handler: "onInk" lost its default binding and stayed black)
    property var pal: K.Kit.bare
    property color ink: pal.over
    property color activeInk: pal.accent
    property color offInk: pal.overVariant
    readonly property var player: MprisController.activePlayer

    spacing: 2
    height: 24

    function playerIcon(p) {
        const names = p ? [p.dbusName, p.desktopEntry, p.identity].join(" ").toLowerCase() : "";
        if (names.includes("spotify"))
            return Icons.spotify;
        if (names.includes("chrom"))
            return Icons.chromium;
        if (names.includes("firefox"))
            return Icons.firefox;
        if (names.includes("telegram"))
            return Icons.telegram;
        return Icons.player;
    }

    K.IconButton {
        anchors.verticalCenter: parent.verticalCenter
        type: K.ButtonBase.Text
        icon: Icons.previous
        size: 16
        inactiveOnColour: root.ink
        active: root.player?.canGoPrevious ?? false
        onClicked: root.player?.previous()
    }

    K.IconButton {
        anchors.verticalCenter: parent.verticalCenter
        type: K.ButtonBase.Text
        icon: Icons.next
        size: 16
        inactiveOnColour: root.ink
        active: root.player?.canGoNext ?? false
        onClicked: root.player?.next()
    }

    // shuffle → repeat all → repeat one → off
    K.IconButton {
        anchors.verticalCenter: parent.verticalCenter
        type: K.ButtonBase.Text
        readonly property bool on: MprisController.hasShuffle || MprisController.loopState !== MprisLoopState.None
        icon: MprisController.hasShuffle ? Icons.shuffle : MprisController.loopState === MprisLoopState.Track ? Icons.repeatOnce : MprisController.loopState === MprisLoopState.Playlist ? Icons.repeat : Icons.shuffle
        size: 16
        inactiveOnColour: on ? root.activeInk : root.offInk
        // a player that doesn't take shuffle / repeat (Spotify over MPRIS) still shows it, off
        disabledOnColour: root.offInk
        active: MprisController.shuffleSupported || MprisController.loopSupported
        onClicked: {
            if (MprisController.hasShuffle) {
                MprisController.setShuffle(false);
                MprisController.setLoopState(MprisLoopState.Playlist);
            } else if (MprisController.loopState === MprisLoopState.Playlist) {
                MprisController.setLoopState(MprisLoopState.Track);
            } else if (MprisController.loopState === MprisLoopState.Track) {
                MprisController.setLoopState(MprisLoopState.None);
            } else {
                MprisController.setShuffle(true);
            }
        }
    }

    // the player: click cycles, right click picks
    Item {
        id: playerButton
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22

        // hover: a primary state layer behind it (the icon keeps its colour)
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.primary
            opacity: picker.visible ? 0.2 : playerMouse.containsMouse ? 0.14 : 0
            Behavior on opacity {
                K.Anim {
                    type: K.Anim.FastEffects
                }
            }
        }
        Icon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            icon: root.playerIcon(root.player)
            size: 16
            color: root.ink
        }
        MouseArea {
            id: playerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (m.button === Qt.RightButton)
                    picker.visible = !picker.visible;
                else
                    MprisController.cyclePlayer(1);
            }
        }
    }

    // the player picker, under the player's icon
    PopupWindow {
        id: picker
        anchor.item: playerButton
        anchor.rect.x: (playerButton.width - width) / 2
        anchor.rect.y: playerButton.height + 10
        implicitWidth: 220
        implicitHeight: pickList.implicitHeight + 16
        color: "transparent"
        visible: false

        FocusGrab {
            active: picker.visible
            windows: [picker]
            onCleared: picker.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: K.Kit.rounding.large
            color: K.Kit.expressive.container
            border.width: 1
            border.color: Colors.outlineVariant

            Column {
                id: pickList
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: [null].concat(MprisController.filteredPlayers)

                    Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool current: modelData ? MprisController.pinned === modelData.identity : MprisController.pinned === ""

                        width: pickList.width
                        height: 32
                        radius: K.Kit.rounding.small
                        color: current ? Colors.primary : K.Kit.expressive.off

                        K.StateLayer {
                            color: row.current ? Colors.overPrimary : Colors.overSurface
                            onClicked: {
                                MprisController.pin(row.modelData);
                                picker.visible = false;
                            }
                        }
                        Icon {
                            id: rowIcon
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            icon: row.modelData ? root.playerIcon(row.modelData) : "auto_mode"
                            size: 16
                            color: row.current ? Colors.overPrimary : Colors.overSurface
                        }
                        K.StyledText {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData ? row.modelData.identity : "Automatic (last played)"
                            font: K.Kit.makeFont(11, Font.Medium)
                            color: row.current ? Colors.overPrimary : Colors.overSurface
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
