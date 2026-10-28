import QtQuick
import qs.components
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K

// Single-line text input; `edited` fires on Enter or when focus leaves, `typed` on every keystroke
// (for a button that depends on what is being typed).
Rectangle {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool mono: false

    signal edited(string value)
    signal typed(string value)

    // the apps' look (R1.5, 2026-10-17): the idle fill, strong text
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    implicitWidth: 220
    implicitHeight: 30
    radius: height / 2
    color: c.off
    border.width: input.activeFocus ? 2 : 0
    border.color: c.accent

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.m
        anchors.rightMargin: Tokens.spacing.m
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: root.c.strong
        selectionColor: root.c.accent
        selectedTextColor: root.c.overAccent
        font.family: root.mono ? Tokens.font.mono : Tokens.font.family
        font.pixelSize: Tokens.font.small
        text: root.value
        onTextEdited: root.typed(text)
        onEditingFinished: {
            if (text !== root.value)
                root.edited(text);
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" && !input.activeFocus
            text: root.placeholder
            color: root.c.weak
            font.pixelSize: Tokens.font.small
        }
    }
}
