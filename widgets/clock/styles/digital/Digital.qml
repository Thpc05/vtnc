import QtQuick

// The style: big, plain text. What the type hands it is `time` (decision
// 3.5b, published in the type's meta) plus `options`, the framework
// channel every style gets (decision 3.4).
//
// The style never reads or writes configuration, and never decides what a
// valid option value is: `options` arrives already resolved against the
// defaults this style's own meta declared, with colour roles already
// turned into colours (decision 3.4d — the style describes, the shell
// decides). So nothing here has to guard against a bad value.
Rectangle {
    id: root

    required property string time
    required property var options

    readonly property string shownTime: options.showSeconds ? time : time.slice(0, 5)

    color: "#202020"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: options.align === "left" ? parent.left : undefined
        anchors.right: options.align === "right" ? parent.right : undefined
        anchors.horizontalCenter: options.align === "center" ? parent.horizontalCenter : undefined
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        text: root.shownTime
        color: root.options.color
        font.pixelSize: root.options.fontSize
    }
}
