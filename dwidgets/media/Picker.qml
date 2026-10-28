import QtQuick
import qs.theme
import qs.services
import qs.kit as K

// The player picker over the whole Dwidget: Automatic (the last one that played) or a pinned app.
Rectangle {
    id: root

    property bool open: false
    property real pad: K.Kit.padding.medium

    anchors.fill: parent
    z: 10
    visible: opacity > 0
    opacity: open ? 1 : 0
    color: Colors.surfaceContainerHigh
    Behavior on opacity {
        K.Anim {
            type: K.Anim.DefaultEffects
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 4

        K.StyledText {
            bottomPadding: 4
            text: "Player"
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Colors.overSurface
        }
        Repeater {
            model: [null].concat(MprisController.filteredPlayers)

            Rectangle {
                id: row
                required property var modelData
                readonly property bool current: modelData ? MprisController.pinned === modelData.identity : MprisController.pinned === ""

                width: parent.width
                height: 30
                radius: height / 2
                color: current ? Colors.primary : Colors.surfaceContainerHighest

                K.StateLayer {
                    radius: height / 2
                    color: row.current ? Colors.overPrimary : Colors.overSurface
                    onClicked: {
                        MprisController.pin(row.modelData);
                        root.open = false;
                    }
                }
                K.MaterialIcon {
                    id: icon
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData ? (row.modelData.isPlaying ? "graphic_eq" : "music_note") : "auto_mode"
                    size: 16
                    color: row.current ? Colors.overPrimary : Colors.overSurface
                }
                K.StyledText {
                    anchors.left: icon.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData ? row.modelData.identity : "Automatic (last played)"
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: row.current ? Colors.overPrimary : Colors.overSurface
                    elide: Text.ElideRight
                }
            }
        }
    }
}
