import QtQuick
import qs.kit as K
import qs.dwidgets.media as DMedia

// The island's media player, "default" style (also on the island card, a Card variant drawn by the
// frame: `pal`): the InfoRow, a small rounded art, the title bold, the artist weak and a short wave, as
// Island → Layout → Media switches them (a click plays / pauses, the wheel skips). The controls are an
// option of every style (MediaControls.qml, 2026-10-15; this was also the "controls" style).
Item {
    id: root

    required property var player
    // the mode's options (Island → Layout → Media): what it shows and its width (0 = auto)
    property var options: ({})
    readonly property real fixedWidth: options.width ?? 0
    readonly property bool showWave: options.showWave ?? false
    // the palette under it (the island card's for the Card variants, else the bare island's)
    property var pal: K.Kit.bare

    // its width follows its texts
    implicitWidth: fixedWidth > 0 ? fixedWidth : Math.ceil(titleRow.implicitWidth)
    implicitHeight: 24

    // title: the InfoRow (art · title · artist · wave, as Island → Layout → Media switches them)
    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.player?.togglePlaying()
            onWheel: w => w.angleDelta.y < 0 ? root.player?.next() : root.player?.previous()
        }

        InfoRow {
            id: titleRow
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            media: infoState
            options: root.options
            available: root.fixedWidth > 0 ? root.fixedWidth : 0
            pal: root.pal
        }
    }
    DMedia.MediaState {
        id: infoState
        active: root.showWave
    }
}
