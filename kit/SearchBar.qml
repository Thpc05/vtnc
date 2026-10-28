import QtQuick
import qs.theme

// A search pill (caelestia's SearchBar, ported): a container pill with a search icon, the
// placeholder fading out as you type, and a clear button.
TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + Kit.spacing.medium
    rightPadding: clearIcon.width + clearIcon.anchors.rightMargin + Kit.spacing.medium
    topPadding: Kit.padding.large
    bottomPadding: Kit.padding.large

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: StyledRect {
        id: bg

        anchors.fill: parent
        color: Kit.expressive.container
        radius: Kit.rounding.full

        StateLayer {
            id: stateLayer

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.forceActiveFocus()
        }
    }

    StyledText {
        id: placeholder

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.leftPadding

        text: root.placeholderText
        color: root.placeholderTextColor
        font: root.font

        opacity: root.text ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    MaterialIcon {
        id: searchIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Kit.padding.large

        text: "search"
        color: Colors.overSurfaceVariant
        size: Math.round(Kit.font.icon.medium.pointSize * 4 / 3 * 0.9)
    }

    IconButton {
        id: clearIcon

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Kit.padding.medium

        icon: "clear"
        type: ButtonBase.Text
        radius: Kit.rounding.full
        radiusMorph: false
        enabled: root.text
        stateLayer.hoverEnabled: enabled
        onClicked: root.clear()

        opacity: root.text ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    TapHandler {
        id: tapHandler
    }
}
