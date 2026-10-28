import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.kit as K

// One item of a summary (2026-10-17): a 28 px lead (an app icon or a thumbnail, else a symbol on a
// small square), the title (strong) and, in a two-line row, its second line (weak); the time or a pin at
// the right. A check for a moment after it acted (`done`). Hover and the ripple from K.StateLayer.
Item {
    id: row

    required property var item
    // the summary (SummaryView): colours and look
    required property Item view
    property bool twoLines: false
    property bool done: false
    property bool interactive: true

    signal clicked

    readonly property bool hasImage: (item.image ?? "") !== ""
    readonly property string sub: item.sub ?? ""

    Item {
        id: lead
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28

        Rectangle {
            anchors.fill: parent
            visible: !row.hasImage
            radius: row.view.look === "shapes" ? 10 : 8
            color: row.view.look === "shapes" ? Qt.alpha(row.view.pal.over, 0.1) : row.view.look === "tones" ? Qt.alpha(row.view.tone, 0.16) : "transparent"
        }
        // a picture (the clipboard's thumbnail) fills its square
        ClippingRectangle {
            anchors.fill: parent
            visible: row.hasImage && !!row.item.picture
            radius: row.view.look === "shapes" ? 10 : 8
            color: "transparent"
            Image {
                anchors.fill: parent
                source: row.item.picture ? row.item.image : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(56, 56)
                asynchronous: true
            }
        }
        IconImage {
            x: 2
            y: 2
            implicitSize: 24
            visible: row.hasImage && !row.item.picture
            source: row.item.picture ? "" : (row.item.image ?? "")
            asynchronous: true
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            visible: !row.hasImage
            text: row.item.lead ?? ""
            size: 16
            fill: 1
            color: row.view.look === "shapes" ? row.view.pal.over : row.view.tone
        }
    }

    Column {
        anchors.left: lead.right
        anchors.leftMargin: 10
        anchors.right: tail.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        K.StyledText {
            width: parent.width
            text: row.item.title ?? ""
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 13
            font.weight: Font.Medium
            color: row.view.strong
        }
        K.StyledText {
            width: parent.width
            visible: row.twoLines && row.sub !== ""
            text: row.sub.replace(/\s+/g, " ")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 11
            color: row.view.weak
        }
    }

    // the time, a pin, or the check after it acted
    Item {
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: row.done || row.item.pinned ? 16 : time.implicitWidth
        height: 16

        K.StyledText {
            id: time
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            visible: !row.done && !row.item.pinned
            text: row.item.time ?? ""
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 11
            color: row.view.weak
        }
        K.MaterialIcon {
            anchors.centerIn: parent
            visible: row.done || !!row.item.pinned
            text: row.done ? "check" : "push_pin"
            size: 16
            weight: 600
            fill: 1
            color: row.view.look === "shapes" ? row.view.pal.accent : row.view.tone
        }
    }

    K.StateLayer {
        visible: row.interactive
        radius: 12
        color: row.view.strong
        onClicked: row.clicked()
    }
}
