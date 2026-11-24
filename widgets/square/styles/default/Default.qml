import QtQuick

// The style: only the look. `text` comes from the type (decision 3.5b),
// `options` is the framework channel of decision 3.4 — see the comment in
// widgets/clock/styles/digital/Digital.qml.
//
// `label` overrides the type's text when it isn't empty. That is this
// style's own idea of what to draw, not a second source of content: the
// type keeps owning the text, and a style that doesn't want the override
// simply doesn't declare the option.
Rectangle {
    id: root

    required property string text
    required property var options

    readonly property string shownText: options.label !== "" ? options.label : text

    color: options.fill
    border.color: "#808080"
    border.width: options.showBorder ? 1 : 0

    Text {
        anchors.centerIn: parent
        text: root.shownText
        color: "white"
    }
}
