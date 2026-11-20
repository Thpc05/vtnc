import QtQuick

// A visibly different look from Digital, so the two styles are tellable
// apart at a glance in the visual test: a small rounded pill, HH:MM only,
// no seconds.
Rectangle {
    id: root

    required property string time

    readonly property string shortTime: time.length >= 5 ? time.slice(0, 5) : time

    radius: height / 2
    color: "#3a6ea5"

    Text {
        anchors.centerIn: parent
        text: root.shortTime
        color: "white"
        font.pixelSize: 14
        font.bold: true
    }
}
