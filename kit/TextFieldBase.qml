import QtQuick
import QtQuick.Templates as T
import qs.theme

// A bare text input (caelestia's TextFieldBase, ported): the kit's text, a primary selection and
// a custom 1.5 px primary cursor that slides to its position and blinks (steady while typing).
T.TextField {
    id: root

    implicitWidth: contentWidth + leftPadding + rightPadding
    implicitHeight: contentHeight + topPadding + bottomPadding

    color: Colors.overSurface
    placeholderTextColor: Colors.overSurfaceVariant
    selectionColor: Qt.alpha(Colors.primary, 0.4)
    selectedTextColor: color

    font: Kit.font.body.small
    renderType: echoMode === TextInput.Password ? Text.QtRendering : Tokens.font.renderType
    cursorVisible: !readOnly
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true

    cursorDelegate: Item {}

    Behavior on color {
        CAnim {}
    }

    Behavior on selectionColor {
        CAnim {}
    }

    StyledRect {
        id: cursor

        property bool disableBlink

        x: root.cursorRectangle.x
        y: root.cursorRectangle.y
        implicitWidth: 1.5
        implicitHeight: root.cursorRectangle.height

        color: Colors.primary
        radius: Kit.rounding.large

        Connections {
            function onCursorPositionChanged(): void {
                if (root.activeFocus && root.cursorVisible) {
                    cursor.opacity = 1;
                    cursor.disableBlink = true;
                    enableBlink.restart();
                }
            }

            target: root
        }

        Timer {
            id: enableBlink

            interval: 500
            onTriggered: cursor.disableBlink = false
        }

        Timer {
            running: root.activeFocus && root.cursorVisible && !cursor.disableBlink
            repeat: true
            triggeredOnStart: true
            interval: 500
            onTriggered: parent.opacity = parent.opacity === 1 ? 0 : 1
        }

        Binding {
            when: !root.activeFocus || !root.cursorVisible
            cursor.opacity: 0
        }

        Behavior on x {
            NumberAnimation {
                // a damped fast spatial curve
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.2, 1, 0.21, 1, 1, 1]
                duration: Kit.anim.durations.expressiveFastEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }
    }
}
