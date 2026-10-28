import QtQuick
import qs.kit as K

// The panel header's switch, in the look's colours (2026-10-16; K.Switch is primary-only): a pill track,
// the accent when on and the idle fill with an outline when off, a thumb sliding across. Tone has no
// solid fills: a tint of the tone and a tone thumb.
Item {
    id: root

    property var look: null
    property bool checked: false
    signal toggled

    readonly property PanelColors c: PanelColors {
        look: root.look
    }

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.c.kind === "tone" ? Qt.alpha(root.c.accent, root.checked ? 0.24 : 0.1) : root.checked ? root.c.accent : root.c.off
        border.width: root.checked ? 0 : 2
        border.color: root.c.weak
        Behavior on color {
            K.CAnim {}
        }
    }
    Rectangle {
        readonly property int size: root.checked ? 16 : 12
        x: root.checked ? root.width - size - 4 : 6
        y: Math.round((root.height - size) / 2)
        width: size
        height: size
        radius: size / 2
        color: root.checked && root.c.kind !== "tone" ? root.c.overAccent : root.checked ? root.c.accent : root.c.weak
        Behavior on x {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on width {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on color {
            K.CAnim {}
        }
    }
    K.StateLayer {
        radius: height / 2
        color: root.c.strong
        onClicked: root.toggled()
    }
}
