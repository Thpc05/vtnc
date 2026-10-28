import QtQuick
import qs.services
import qs.theme
import qs.kit as K
import qs.dwidgets

// Shown only while a screen recording runs (stage 7, 2026-10-08); a click stops it. Styles:
//  - dot (A): a pulsing error dot and the elapsed time in error
//  - pill (B): the dot and the time on an errorContainer pill
//  - stop (C): a round error stop button (its square rounds on hover) and the time beside it
Item {
    id: root

    property string style: "dot"

    implicitWidth: ScreenTools.recording ? row.implicitWidth + (style === "pill" ? 2 * K.Kit.padding.small : 0) : 0
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        visible: root.style === "pill" && ScreenTools.recording
        radius: height / 2
        color: Colors.errorContainer
    }

    Row {
        id: row
        x: root.style === "pill" ? K.Kit.padding.small : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        visible: ScreenTools.recording

        // dot / pill: the pulsing dot
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style !== "stop"
            width: 8
            height: 8
            radius: 4
            color: Colors.error

            // breathing (kit motion, 2026-10-15; was raw 700 ms sines): the slow effects curve each way,
            // held a moment at each end (about the old 1.4 s cycle)
            SequentialAnimation on opacity {
                running: ScreenTools.recording && K.Kit.anim.enabled
                loops: Animation.Infinite
                K.Anim {
                    to: 0.3
                    type: K.Anim.SlowEffects
                }
                PauseAnimation {
                    duration: 400
                }
                K.Anim {
                    to: 1
                    type: K.Anim.SlowEffects
                }
                PauseAnimation {
                    duration: 400
                }
            }
        }

        // stop: a round error button with a square
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "stop"
            width: 20
            height: 20
            radius: 10
            color: Colors.error

            Rectangle {
                x: 6
                y: 6
                width: 8
                height: 8
                radius: mouse.containsMouse ? 4 : 1.5
                color: Colors.overError
                Behavior on radius {
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }
            }
        }

        // the island's number standard (Rubik bold, cap height centred; 2026-10-15)
        CapText {
            anchors.verticalCenter: parent.verticalCenter
            height: 12
            text: ScreenTools.elapsedText
            pixelSize: 11
            weight: 700
            color: root.style === "pill" ? Colors.overErrorContainer : Colors.error
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ScreenTools.stopRecording()
    }
}
