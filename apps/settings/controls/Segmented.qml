import QtQuick
import qs.components
import qs.theme
import qs.dwidgets
import qs.dwidgets.quick.panels
import qs.kit as K

// Segmented switch: options side by side with a sliding highlight; they wrap to more lines when
// they don't fit `maxWidth` (SettingRow sets it).
// options: [{ value, label?, icon? }]
// In the apps' look (R1.5, 2026-10-17): Shapes and Two tones the choice filled with the accent, Tone (no
// solid fills) a tint of it; the track the look's idle fill. Labels centred on their caps.
Rectangle {
    id: root

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property bool tone: c.kind === "tone"
    readonly property color onColor: tone ? c.accent : c.overAccent

    property var options: []
    property var value
    property int buttonHeight: 26
    property int minButtonWidth: 26
    // the widest it may get (0 = no limit): past it the options wrap
    property real maxWidth: 0
    // all options on one line
    property real naturalWidth: 0

    function measure() {
        let w = 0;
        for (let i = 0; i < repeater.count; i++)
            w += repeater.itemAt(i)?.width ?? 0;
        naturalWidth = w;
    }

    signal selected(var value)

    readonly property int currentIndex: options.findIndex(o => o.value === value)

    implicitWidth: row.width + 4
    implicitHeight: row.implicitHeight + 4
    // a pill; wrapped onto more lines, a rounded box
    radius: Math.min(height / 2, K.Kit.rounding.large)
    color: c.off

    Rectangle {
        readonly property Item target: repeater.count > 0 && root.currentIndex >= 0 ? repeater.itemAt(root.currentIndex) : null
        visible: target !== null
        x: 2 + (target?.x ?? 0)
        y: 2 + (target?.y ?? 0)
        width: target?.width ?? 0
        height: root.buttonHeight
        radius: height / 2
        // the accent (was secondaryContainer: in low-chroma palettes it nearly matched the track, the
        // choice didn't stand out — user); Tone: a tint
        color: root.tone ? Qt.alpha(root.c.accent, 0.28) : root.c.accent
        Behavior on color {
            K.CAnim {}
        }
        Behavior on x {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on y {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on width {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
    }

    Flow {
        id: row
        x: 2
        y: 2
        width: root.maxWidth > 0 ? Math.min(root.naturalWidth, root.maxWidth - 4) : root.naturalWidth

        Repeater {
            id: repeater
            model: root.options
            onItemAdded: Qt.callLater(root.measure)
            onItemRemoved: Qt.callLater(root.measure)

            Item {
                id: option
                required property var modelData
                required property int index
                readonly property bool isCurrent: index === root.currentIndex

                width: Math.max(root.minButtonWidth, content.implicitWidth + 2 * Tokens.spacing.s)
                height: root.buttonHeight
                // the labels (CapText) know their width a moment later: measure again
                onWidthChanged: Qt.callLater(root.measure)

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.xs

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!option.modelData.icon
                        icon: option.modelData.icon ?? ""
                        size: 14
                        color: option.isCurrent ? root.onColor : root.c.strong
                    }
                    CapText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!option.modelData.label
                        text: option.modelData.label ?? ""
                        family: K.Kit.family
                        pixelSize: Tokens.font.small
                        weight: option.isCurrent && root.tone ? 700 : 600
                        color: option.isCurrent ? root.onColor : root.c.strong
                        Behavior on color {
                            K.CAnim {}
                        }
                    }
                }

                K.StateLayer {
                    radius: height / 2
                    color: option.isCurrent ? root.onColor : root.c.strong
                    onClicked: root.selected(option.modelData.value)
                }
            }
        }
    }
}
