import QtQuick
import qs.kit as K

// Password input with a show/hide eye, in the panel's look (2026-10-16): a pill on the idle fill, the
// accent ring while focused; `accepted(text)` on Enter.
Rectangle {
    id: root

    property var look: null
    property string placeholder: "Password"
    property bool shown: false
    signal accepted(string text)

    readonly property PanelColors c: PanelColors {
        look: root.look
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 200
    implicitHeight: 32
    radius: height / 2
    color: c.off
    border.width: input.activeFocus ? 2 : 0
    border.color: c.accent

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: eye.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        echoMode: root.shown ? TextInput.Normal : TextInput.Password
        color: root.c.strong
        selectionColor: root.c.accent
        selectedTextColor: root.c.overAccent
        font.family: K.Kit.family
        font.pixelSize: 12
        onAccepted: if (text !== "")
            root.accepted(text)

        K.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: root.c.weak
            font.family: K.Kit.family
            font.pixelSize: 12
        }
    }

    K.IconButton {
        id: eye
        type: K.ButtonBase.Text
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: root.shown ? "visibility_off" : "visibility"
        size: 14
        label.color: root.c.weak
        onClicked: root.shown = !root.shown
    }
}
