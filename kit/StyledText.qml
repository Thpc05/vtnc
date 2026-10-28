pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

// Text in the kit's font; `animate` fades a text change through.
Text {
    id: root

    property bool animate: false

    renderType: Tokens.font.renderType
    textFormat: Text.PlainText
    color: Colors.overSurface
    font: Kit.font.body.small

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}
