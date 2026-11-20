import QtQuick

// The only style for vtnc.island-editor. Everything the type hands it is
// listed here (decision 3.5b): the island's current anchor/offset/size/
// layer/page, the closed lists of edges and layers, and the five functions
// that are the only way this ever changes anything.
Rectangle {
    id: root

    required property string islandName
    required property var anchor
    required property var offset
    required property var size
    required property string islandLayer
    required property string pageName
    required property var pageNames
    required property var edges
    required property var layers
    required property var setAnchorEdge
    required property var nudgeOffset
    required property var nudgeSize
    required property var setLayer
    required property var setPage

    color: "#262626"
    border.color: "#3a3a3a"
    border.width: 1
    radius: 4

    component Chip: Rectangle {
        id: chip
        property string label
        property bool active
        signal activated

        width: label.length * 8 + 20
        height: 24
        radius: 12
        color: active ? "#3a6ea5" : "#3a3a3a"

        Text {
            anchors.centerIn: parent
            text: chip.label
            color: "white"
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            onClicked: chip.activated()
        }
    }

    component Stepper: Row {
        property string label
        property int value
        signal decremented
        signal incremented

        spacing: 4

        Text {
            text: label + ":"
            color: "#cccccc"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: decrementButton
            width: 20; height: 20; radius: 3; color: "#3a3a3a"
            Text { anchors.centerIn: parent; text: "-"; color: "white" }
            MouseArea { anchors.fill: parent; onClicked: decrementButton.parent.decremented() }
        }
        Text {
            text: value
            color: "white"
            font.pixelSize: 12
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: incrementButton
            width: 20; height: 20; radius: 3; color: "#3a3a3a"
            Text { anchors.centerIn: parent; text: "+"; color: "white" }
            MouseArea { anchors.fill: parent; onClicked: incrementButton.parent.incremented() }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Text {
            text: root.islandName
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }

        Row {
            spacing: 8
            Text { text: "anchor:"; color: "#cccccc"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: root.edges
                delegate: Chip {
                    required property string modelData
                    label: modelData
                    active: !!root.anchor[modelData]
                    onActivated: root.setAnchorEdge(modelData, !active)
                }
            }
        }

        Row {
            spacing: 16
            Stepper {
                label: "offset x"
                value: root.offset.x ?? 0
                onDecremented: root.nudgeOffset("x", -1)
                onIncremented: root.nudgeOffset("x", 1)
            }
            Stepper {
                label: "offset y"
                value: root.offset.y ?? 0
                onDecremented: root.nudgeOffset("y", -1)
                onIncremented: root.nudgeOffset("y", 1)
            }
        }

        Row {
            spacing: 16
            Stepper {
                label: "size w"
                value: root.size.w ?? 1
                onDecremented: root.nudgeSize("w", -1)
                onIncremented: root.nudgeSize("w", 1)
            }
            Stepper {
                label: "size h"
                value: root.size.h ?? 1
                onDecremented: root.nudgeSize("h", -1)
                onIncremented: root.nudgeSize("h", 1)
            }
        }

        Row {
            spacing: 8
            Text { text: "layer:"; color: "#cccccc"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: root.layers
                delegate: Chip {
                    required property string modelData
                    label: modelData
                    active: modelData === root.islandLayer
                    onActivated: root.setLayer(modelData)
                }
            }
        }

        Row {
            spacing: 8
            Text { text: "page:"; color: "#cccccc"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: root.pageNames
                delegate: Chip {
                    required property string modelData
                    label: modelData
                    active: modelData === root.pageName
                    onActivated: root.setPage(modelData)
                }
            }
        }
    }
}
