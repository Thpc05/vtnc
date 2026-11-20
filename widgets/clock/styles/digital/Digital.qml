import QtQuick

// The style: big, plain text — everything the type hands it is `time`
// (decision 3.5b).
Rectangle {
    id: root

    required property string time

    color: "#202020"

    Text {
        anchors.centerIn: parent
        text: root.time
        color: "white"
        font.pixelSize: 20
    }
}
