import QtQuick

// The only style for vtnc.autohide-settings: one Stepper for the global
// trigger distance (decision 3.5b — everything the type hands it is
// listed here).
Rectangle {
    id: root

    required property int distance
    required property var nudgeDistance

    color: "#1f1f1f"
    border.color: "#3a3a3a"
    border.width: 1
    radius: 4

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: "autohide trigger distance (cells):"
            color: "#cccccc"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: decrementButton
            width: 20; height: 20; radius: 3; color: "#3a3a3a"
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "-"; color: "white" }
            MouseArea { anchors.fill: parent; onClicked: root.nudgeDistance(-1) }
        }
        Text {
            text: root.distance
            color: "white"
            font.pixelSize: 12
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: incrementButton
            width: 20; height: 20; radius: 3; color: "#3a3a3a"
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "+"; color: "white" }
            MouseArea { anchors.fill: parent; onClicked: root.nudgeDistance(1) }
        }
    }
}
