import QtQuick

// The style: only the look. Everything it needs from the type arrives via
// `text` (decision 3.5b — the type publishes what it hands to styles).
Rectangle {
    id: root

    required property string text

    color: "#3a3a3a"
    border.color: "#808080"
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: root.text
        color: "white"
    }
}
