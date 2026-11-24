import QtQuick

// A visibly different look from Digital, so the two styles are tellable
// apart at a glance in the visual test: a small rounded pill.
//
// Cutting the seconds used to be hard-coded here (`time.slice(0, 5)`) —
// it was an option in disguise, and since 0.510 it is a real one, declared
// in this style's meta. Ver o comentario em Digital.qml sobre o canal
// `options`.
Rectangle {
    id: root

    required property string time
    required property var options

    readonly property string shownTime: options.showSeconds ? time : time.slice(0, 5)

    radius: height / 2
    color: options.fill

    Text {
        anchors.centerIn: parent
        text: root.shownTime
        color: "white"
        font.pixelSize: 14
        font.bold: true
    }
}
