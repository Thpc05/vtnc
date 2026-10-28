import QtQuick
import qs.theme

// One look of a multi-style iwidget. Switching styles fades through, like the island pages:
// the old layer fades out in the first 30% of the morph, the new one fades in from 30% to 80%,
// while the slot's width follows the island's curve.
// Explicit animations (not a Behavior): the timing depends on `active` itself.
Item {
    id: root

    property bool active: false
    readonly property int duration: Tokens.anim.duration

    visible: opacity > 0

    Component.onCompleted: opacity = active ? 1 : 0
    onActiveChanged: {
        if (duration <= 0) {
            fadeIn.stop();
            fadeOut.stop();
            opacity = active ? 1 : 0;
        } else if (active) {
            fadeOut.stop();
            fadeIn.restart();
        } else {
            fadeIn.stop();
            fadeOut.restart();
        }
    }

    SequentialAnimation {
        id: fadeIn
        PauseAnimation {
            duration: root.duration * 0.3
        }
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: root.duration * 0.5
            easing.type: Tokens.anim.fadeEasing
        }
    }
    NumberAnimation {
        id: fadeOut
        target: root
        property: "opacity"
        to: 0
        duration: root.duration * 0.3
        easing.type: Tokens.anim.fadeEasing
    }
}
