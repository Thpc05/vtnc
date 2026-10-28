import QtQuick
import qs.theme
import qs.services
import qs.core
import qs.components
import qs.kit as K
import qs.dwidgets

// The notifications Iwidget (stage 7, 2026-10-08). Styles:
//  - bell: filled primary while there are notifications, bell-Z in do-not-disturb
//  - badge: the bell with a small primary count badge at its corner
//  - count: with notifications the count on a primary pill with a small bell; without, a weak bell
// It shakes when rung (a notification shown only by it, "widget" mode); a click toggles
// do-not-disturb.
Item {
    id: root

    property string style: "bell"
    // this session's notifications (the saved history doesn't count; user, 2026-10-15)
    readonly property int count: Notifications.sessionList.length

    // the bell's click (2026-10-17): left opens the Notifications app (apps/notifications), right toggles
    // do not disturb
    function press(button: int) {
        if (button === Qt.RightButton)
            Notifications.silent = !Notifications.silent;
        else
            Runtime.toggleApp("notifications");
    }
    readonly property bool pillShown: style === "count" && count > 0
    readonly property string bellIcon: Notifications.silent ? Icons.bellZ : (count > 0 ? Icons.bellRinging : Icons.bell)

    implicitWidth: pillShown ? countPill.implicitWidth : 26
    implicitHeight: 26

    // vtnc: the screen whose bell this is (set by WidgetSlot); it shakes when Runtime rings it
    property var screen: null

    Item {
        id: shakeContainer
        anchors.centerIn: parent
        width: root.pillShown ? countPill.width : 26
        height: 26

        // the ring (kit motion, 2026-10-15; was five raw keyframes): a quick tilt each way, then the fast
        // spatial curve brings it back, its overshoot swinging it once more past the rest
        SequentialAnimation {
            id: shakeAnimation

            K.Anim {
                target: shakeContainer
                property: "rotation"
                to: -16
                type: K.Anim.FastEffects
            }
            K.Anim {
                target: shakeContainer
                property: "rotation"
                to: 10
                type: K.Anim.FastEffects
            }
            K.Anim {
                target: shakeContainer
                property: "rotation"
                to: 0
                type: K.Anim.FastSpatial
            }
        }

        // bell / badge (and count without notifications): filled while there are notifications
        // (M3's on); paused bell in do-not-disturb
        IconButton {
            anchors.centerIn: parent
            visible: !root.pillShown
            size: Tokens.font.large // as the volume icon
            icon: root.bellIcon
            fill: root.count > 0 && root.style !== "count" ? 1 : 0
            color: root.style === "count" ? Colors.overSurfaceVariant : root.count > 0 ? Colors.primary : Colors.overBackground // vtnc: accent instead of error
            // left: the Notifications app; right: do not disturb (2026-10-17)
            onClicked: m => root.press(m.button)
        }

        // badge: the count at the bell's corner
        Rectangle {
            visible: root.style === "badge" && root.count > 0
            x: parent.width - width + 2
            y: -1
            width: Math.max(height, badgeText.implicitWidth + 6)
            height: 13
            radius: height / 2
            color: Colors.primary
            // (the island's number standard, small: Rubik bold, cap height centred)
            CapText {
                id: badgeText
                anchors.centerIn: parent
                height: 9
                text: root.count > 99 ? "99+" : root.count
                pixelSize: 9
                weight: 700
                color: Colors.overPrimary
            }
        }

        // count: the number on a primary pill with a small bell
        Rectangle {
            id: countPill
            anchors.centerIn: parent
            visible: root.pillShown
            implicitWidth: pillRow.implicitWidth + 2 * K.Kit.padding.small
            width: implicitWidth
            height: 22
            radius: height / 2
            color: Colors.primary

            K.StateLayer {
                radius: height / 2
                color: Colors.overPrimary
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: m => root.press(m.button)
            }
            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: 3
                K.MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bellIcon
                    size: 14
                    fill: 1
                    color: Colors.overPrimary
                }
                CapText {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 12
                    text: root.count
                    pixelSize: 11
                    weight: 700
                    color: Colors.overPrimary
                }
            }
        }
    }

    // vtnc: rung by the notification presenter ("widget" mode) instead of on every popup; the
    // short wait lets a bell that was hidden in this mode appear first (Island flashes it)
    Timer {
        id: ringDelay
        interval: Tokens.anim.duration * 0.6
        onTriggered: shakeAnimation.restart()
    }
    Connections {
        target: Runtime
        function onBellRang(screenName) {
            if (!root.screen || root.screen.name === screenName)
                ringDelay.restart();
        }
    }
}
