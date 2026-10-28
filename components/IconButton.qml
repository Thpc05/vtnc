import QtQuick
import qs.theme
import qs.kit as K

// A clickable icon (theme/Icons.qml) as caelestia's Text icon button: a round state layer (hover
// 8 %, a ripple on press) whose corners tighten while pressed, the icon filled. `active: false`
// dims it and ignores input. `hoverColor` tints the icon on hover (off by default, as caelestia).
Item {
    id: root

    property string icon: ""
    property int size: Tokens.font.large
    property color color: Colors.overSurfaceVariant
    property color hoverColor: color
    property bool active: true
    property real fill: 1

    readonly property bool hovered: layer.containsMouse

    signal clicked(var mouse)

    implicitWidth: size + 10
    implicitHeight: size + 10
    opacity: active ? 1 : 0.38

    K.StateLayer {
        id: layer
        radius: pressed ? K.Kit.rounding.small : width / 2
        color: root.color
        disabled: !root.active
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)

        Behavior on radius {
            K.Anim {
                type: K.Anim.DefaultEffects
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.size
        fill: root.fill
        color: root.hovered && root.active ? root.hoverColor : root.color

        Behavior on color {
            K.CAnim {}
        }
    }
}
