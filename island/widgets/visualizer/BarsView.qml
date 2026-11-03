import QtQuick

// Visualizer "bars": a rounded 3 px bar per level, mirrored around the middle, from `minHeight` (silent)
// up to `maxHeight`. The
// heights are even whole pixels so each bar sits exactly centred (an odd height can't: its edges took
// turns jumping a pixel, the bars trembled — user); the levels come already smoothed (Widget.qml).
Item {
    id: root

    property var levels: []
    property color colour
    property int maxHeight: 20
    property int minHeight: 2

    Repeater {
        model: root.levels.length

        Rectangle {
            required property int index
            readonly property real level: root.levels[index] ?? 0
            x: Math.round((index + 0.5) * root.width / root.levels.length - width / 2)
            y: Math.round((root.height - height) / 2)
            width: 3
            height: root.minHeight + 2 * Math.round(level * (root.maxHeight - root.minHeight) / 2)
            radius: 1.5
            color: root.colour
        }
    }
}
