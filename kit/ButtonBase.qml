import QtQuick
import qs.theme

// The M3 button shape every kit button builds on (caelestia's ButtonBase, ported): a rounded
// rect whose radius morphs, large at rest → medium when checked → small while pressed (or a pill
// with `isRound`), a state layer, and the colors by `type`:
//  - Filled: the accent (primary); as a toggle, off is a container
//  - Tonal: secondaryContainer, secondary when checked
//  - Text: no background, only the state layer
StyledRect {
    id: root

    enum ButtonType {
        Filled,
        Tonal,
        Text
    }

    property bool checked
    property alias disabled: stateLayer.disabled
    property bool isToggle
    property bool isRound

    property bool radiusMorph: true
    property alias shapeMorph: stateLayer.shapeMorph

    property font font: Kit.font.body.small
    property int type: ButtonBase.Filled

    property real padding
    property real horizontalPadding: padding
    property real verticalPadding: padding

    readonly property alias pressed: stateLayer.pressed
    readonly property alias hovered: stateLayer.containsMouse
    readonly property alias stateLayer: stateLayer
    readonly property alias radiusAnim: radiusAnim

    property color activeColour
    property color inactiveColour
    property color activeOnColour
    property color inactiveOnColour
    property color disabledColour: Qt.alpha(Colors.overSurface, 0.1)
    property color disabledOnColour: Qt.alpha(Colors.overSurface, 0.38)

    property bool internalChecked
    // M3's shape morph: the button grows 24 px while pressed, whatever its width
    property real shapeMorphExpansion: shapeMorph && pressed ? 24 : 0
    readonly property color onColour: disabled ? disabledOnColour : internalChecked ? activeOnColour : inactiveOnColour

    property real pressedRadius: Kit.rounding.small
    property real checkedRadius: Kit.rounding.medium
    property real defaultRadius: Kit.rounding.large

    signal clicked

    onCheckedChanged: internalChecked = checked
    Component.onCompleted: internalChecked = checked

    radius: {
        if (radiusMorph && pressed)
            return pressedRadius;
        if (internalChecked)
            return checkedRadius;
        if (isRound)
            return (implicitHeight || height) / 2 * Math.min(1, Kit.scale.rounding);
        return defaultRadius;
    }
    color: type === ButtonBase.Text ? "transparent" : disabled ? disabledColour : internalChecked ? activeColour : inactiveColour

    StateLayer {
        id: stateLayer

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        onClicked: {
            if (root.isToggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    Behavior on radius {
        Anim {
            id: radiusAnim

            type: Anim.DefaultEffects
        }
    }

    Behavior on shapeMorphExpansion {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
