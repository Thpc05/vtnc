import QtQuick

// Visualizer "dots": a small 4 px dot per level, simply on (the colour) or off (faint) as its level
// passes `threshold` (island.visualizer.dotThreshold %, a third by default; user: no size or colour
// variance; a very quick switch).
Item {
    id: root

    property var levels: []
    property color colour
    // 0…1: the level a dot turns on at
    property real threshold: 0.33

    Repeater {
        model: root.levels.length

        Rectangle {
            required property int index
            readonly property bool on: (root.levels[index] ?? 0) > root.threshold
            width: 4
            height: 4
            radius: 2
            x: Math.round((index + 0.5) * root.width / root.levels.length - width / 2)
            y: Math.round((root.height - height) / 2)
            color: on ? root.colour : Qt.alpha(root.colour, 0.25)
            Behavior on color {
                ColorAnimation {
                    duration: 60
                }
            }
        }
    }
}
