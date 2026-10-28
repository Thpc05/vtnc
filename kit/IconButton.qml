import QtQuick
import qs.theme

// A Material Symbols icon button (caelestia's IconButton, ported): square, `padding` small (Text:
// almost none), even-sized so the glyph centres. Filled: primary (as a toggle: off = container,
// on = primary); Tonal: secondaryContainer → secondary; Text: no background. The icon fills when
// checked (or always, when it isn't a toggle).
// `size` (px) overrides the icon size; `active: false` disables it (dimmed, no clicks).
ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label
    property real size: 0
    property bool active: true

    font: Kit.font.icon.medium
    padding: type === ButtonBase.Text ? Kit.padding.extraSmall / 2 : Kit.padding.small
    disabled: !active

    activeColour: type === ButtonBase.Filled ? Colors.primary : Colors.secondary
    inactiveColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colors.primary;
        return type === ButtonBase.Filled ? Kit.expressive.container : Colors.secondaryContainer;
    }
    activeOnColour: type === ButtonBase.Filled ? Colors.overPrimary : type === ButtonBase.Tonal ? Colors.overSecondary : Colors.primary
    inactiveOnColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colors.overPrimary;
        return type === ButtonBase.Tonal ? Colors.overSecondaryContainer : Colors.overSurfaceVariant;
    }
    // vtnc: a Text button that's disabled only dims its icon (no grey disc behind)
    disabledOnColour: Qt.alpha(type === ButtonBase.Text ? inactiveOnColour : Colors.overSurface, 0.38)

    implicitWidth: implicitHeight
    implicitHeight: {
        // even, so the icon is centred
        const h = Math.ceil(label.implicitHeight + padding * 2);
        return h % 2 !== 0 ? h + 1 : h;
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        fontStyle: root.font
        size: root.size
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
