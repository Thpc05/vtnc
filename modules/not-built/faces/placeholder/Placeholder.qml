import QtQuick

Rectangle {
    id: root

    required property string pageName

    color: "#222222"

    Text {
        anchors.centerIn: parent
        text: root.pageName + " hasn't been built yet."
        color: "#888888"
        font.pixelSize: 16
    }
}
