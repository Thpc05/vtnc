import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.services
import qs.kit as K

// The Mixer (2026-10-16, the "hero" panels): the output and the input side by side (user, 2026-10-17),
// each its default on top (name, volume, a slider; the mark mutes) and its devices under it (a click
// makes one the default); the apps playing (icon, name, percent, a slider; the icon mutes) under them
// (wide: the devices stacked at the left, the apps at the right). `show` (the toggle Dwidget's option,
// 2026-10-27, user) picks the parts: output · input · apps; the shown ones take the room.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    readonly property int gap: 12
    // the parts shown (at least one; none picked shows them all)
    property var show: ["output", "input", "apps"]
    readonly property var parts: (show ?? []).length > 0 ? show : ["output", "input", "apps"]
    readonly property bool showApps: parts.includes("apps")
    // the device columns: true = the output (sink), false = the input
    readonly property var deviceColumns: [true, false].filter(s => parts.includes(s ? "output" : "input"))
    readonly property bool showDevices: deviceColumns.length > 0
    // the mixer's panel sizes are wide: the devices at the left, the apps at the right (with both)
    readonly property bool wide: showApps && showDevices && width >= height * 1.1

    // app nodes only report their volume / name while tracked
    PwObjectTracker {
        objects: Audio.outputAppNodes
    }

    function appIcon(node) {
        const name = node?.properties?.["application.icon-name"] ?? "";
        return name ? Quickshell.iconPath(name, true) : "";
    }

    // the devices: output and input side by side (wide: stacked at the left), each scrolling
    Item {
        id: devicesArea
        visible: root.showDevices
        width: root.wide ? Math.round((root.width - root.gap) / 2) : root.width
        // stacked: as tall as the taller column needs, at most 55 % (the rest is the apps'); no apps: all
        height: !root.showDevices ? 0 : root.wide || !root.showApps ? root.height : Math.min(Math.round((root.height - 8) * 0.55), tallest)
        // the taller device column's content (itemAt() isn't reactive: `count` re-reads it once they exist)
        readonly property real tallest: {
            columns.count;
            return Math.max(columns.itemAt(0)?.contentHeight ?? 0, columns.itemAt(1)?.contentHeight ?? 0);
        }

        Repeater {
            id: columns
            model: root.deviceColumns

            Flickable {
                id: devices
                required property bool modelData
                required property int index
                readonly property int count: root.deviceColumns.length
                readonly property real half: count > 1 ? Math.round((devicesArea.width - root.gap) / 2) : devicesArea.width
                // stacked panel: the columns side by side; wide: one column, output then input
                x: root.wide ? 0 : index * (half + root.gap)
                y: root.wide && index === 1 ? Math.round(devicesArea.height / 2) : 0
                width: root.wide ? devicesArea.width : half
                height: root.wide && count > 1 ? Math.round(devicesArea.height / 2) : devicesArea.height
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                MixerDevices {
                    id: column
                    width: devices.width
                    look: root.look
                    sink: devices.modelData
                }
            }
        }
    }

    // the apps
    Item {
        id: appsArea
        visible: root.showApps
        x: root.wide ? devicesArea.width + root.gap : 0
        y: root.wide || !root.showDevices ? 0 : devicesArea.height + 8
        width: root.width - x
        height: root.height - y

        PanelSection {
            id: appsSection
            width: parent.width
            look: root.look
            text: "Apps"
        }

        ListView {
            id: apps
            anchors.top: appsSection.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Audio.outputAppNodes

            delegate: Column {
                id: app
                required property var modelData
                readonly property var audio: modelData?.audio ?? null
                readonly property string iconSource: root.appIcon(modelData)

                width: apps.width
                spacing: 2

                Item {
                    width: parent.width
                    height: 22

                    Item {
                        id: icon
                        width: 22
                        height: 22

                        K.StateLayer {
                            radius: K.Kit.rounding.extraSmall
                            color: root.c.strong
                            onClicked: if (app.audio)
                                app.audio.muted = !app.audio.muted
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 16
                            visible: app.iconSource !== ""
                            source: app.iconSource
                            opacity: app.audio?.muted ? 0.4 : 1
                        }
                        K.MaterialIcon {
                            anchors.centerIn: parent
                            visible: app.iconSource === "" || (app.audio?.muted ?? false)
                            text: app.audio?.muted ? "volume_off" : "graphic_eq"
                            size: 16
                            color: root.c.weak
                        }
                    }
                    K.StyledText {
                        anchors.left: icon.right
                        anchors.leftMargin: 8
                        anchors.right: percent.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: Audio.appNodeDisplayName(app.modelData)
                        elide: Text.ElideRight
                        font.family: K.Kit.family
                        font.variableAxes: K.Kit.axes
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: app.audio?.muted ? root.c.weak : root.c.strong
                    }
                    K.StyledText {
                        id: percent
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round((app.audio?.volume ?? 0) * 100) + "%"
                        font.family: K.Kit.family
                        font.pixelSize: 11
                        color: root.c.weak
                    }
                }
                K.M3Slider {
                    width: parent.width
                    height: 12
                    vertical: false
                    trackThickness: 5
                    activeColor: root.c.accent
                    inactiveColor: root.c.off
                    value: app.audio?.volume ?? 0
                    muted: app.audio?.muted ?? false
                    onMoved: v => {
                        if (app.audio)
                            app.audio.volume = v;
                    }
                }
            }

            K.StyledText {
                anchors.centerIn: parent
                visible: apps.count === 0
                text: "Nothing playing"
                font.family: K.Kit.family
                font.pixelSize: 12
                color: root.c.weak
            }
        }
    }
}
