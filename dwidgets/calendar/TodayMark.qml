import QtQuick
import qs.dwidgets
import qs.kit as K

// Today's number on its mark, per look (the Iwidget family's "on" mark):
//  - shapes: an accent M3 shape, a random one each time the dashboard opens
//  - tones: a rounded square in the tone
//  - tone: no fill: the number heavier, a dot under it
Item {
    id: root

    required property Item cal
    property int day: 1
    property int digit: 12

    K.M3Shape {
        anchors.fill: parent
        visible: root.cal.look === "shapes"
        shape: root.cal.todayShape
        animate: !root.cal.todayRandom.instant
        color: root.cal.markFill
    }
    Rectangle {
        anchors.fill: parent
        visible: root.cal.look === "tones"
        radius: Math.round(width * 0.3)
        color: root.cal.markFill
    }
    CapText {
        id: number
        anchors.fill: parent
        text: root.day
        // the shapes' points crowd a big number: 42 % of the mark at most there
        pixelSize: root.cal.look === "shapes" ? Math.min(root.digit, Math.round(root.width * 0.42)) : root.digit
        weight: root.cal.look === "tone" ? Math.max(700, root.cal.dayWeight + 200) : Math.max(600, root.cal.dayWeight)
        color: root.cal.markInk
    }
    Rectangle {
        visible: root.cal.look === "tone"
        width: root.digit >= 20 ? 6 : 4
        height: width
        radius: width / 2
        x: Math.round((parent.width - width) / 2)
        y: Math.min(parent.height - height, Math.round(number.baseY + (root.digit >= 20 ? 4 : 3)))
        color: root.cal.markInk
    }
}
