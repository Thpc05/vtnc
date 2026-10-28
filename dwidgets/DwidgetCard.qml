import QtQuick
import qs.kit as K

// The card behind a Dwidget's Card variant (2026-10-11), the dashboard's IwidgetFrame: the island
// card's look at dashboard scale: the most rounded it can be (a pill one row tall, else
// rounding.extraLarge), the card colour (Kit.card, Appearance → General → Cards) and a compact
// padding. `pal` is what to draw with on it (Kit.bare without the card); `pad` the inset for the content.
Item {
    id: root

    property bool card: false

    readonly property var pal: card ? K.Kit.card : K.Kit.bare
    readonly property real radius: Math.min(height / 2, K.Kit.rounding.extraLarge)
    readonly property int pad: padFor(width, height)
    // the padding at another size (the Dwidget's target rect)
    function padFor(w: real, h: real): int {
        return card ? Math.max(6, Math.min(14, Math.round(Math.min(w, h) * 0.16))) : 0;
    }

    Rectangle {
        anchors.fill: parent
        visible: root.card
        radius: root.radius
        color: root.pal.fill
        Behavior on color {
            K.CAnim {}
        }
    }
}
