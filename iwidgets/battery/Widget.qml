import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.kit as K
import qs.dwidgets
import "../../dwidgets/quick" as DQ

// The battery (stage 7, 2026-10-08; redone 2026-10-11 in the Iwidget family); hidden without one.
// Styles, each also on the island card (Card variants: `pal`):
//  - shapes / tones / tone: the Quick configs' mark (dwidgets/quick/QMark.qml) with the level's symbol,
//    "on" while plugged in, error when low; the number after it (Two tones: bold in the tone, "%" weak;
//    Tone: in the tone, heavier plugged in; Shapes: onSurface)
//  - ring: a closed ring (K.WavyRing) in the tone around the number, wavy while plugged in
//  - arc (2026-10-11, user): the ring with only its charged arc, no track for the rest
// (upright / text, then Default, went: 2026-10-11, user; they migrate to Shapes.)
// Options (Island → Layout → Battery, island.battery): `color` (the tone's role, as the Quick configs)
// and per island mode `show`: both / icon / text.
Item {
    id: root

    property string style: "shapes"
    // from the frame: the island mode and the palette (the island card's, or the bare island's)
    property string mode: "compact"
    property var pal: K.Kit.bare

    readonly property string show: Store.island.battery?.[mode]?.show || "both"
    readonly property bool showIcon: show !== "text"
    readonly property bool showText: show !== "icon"
    // hidden above a level (island.battery.hideAbove %, 0 = never; user 2026-10-15): it collapses
    readonly property int hideAbove: Store.island.battery?.hideAbove ?? 0
    readonly property bool levelHidden: hideAbove > 0 && Battery.percentage > hideAbove

    DQ.ToneColors {
        id: colors
        pal: root.pal
        role: Store.island.battery?.color || "primary"
    }
    readonly property color tone: Battery.low ? Colors.error : colors.tone
    readonly property string number: Math.round(Battery.percentage)
    // the level's Material symbol, Android 16's lying battery (the standing ones blur at 14 px): 1…6
    // bars (empty has no "frame_0"), full, a bolt while plugged in (charging, full or at a charge limit)
    readonly property int bars: Math.round(Battery.percentage / 100 * 6)
    readonly property string symbol: Battery.pluggedIn ? "battery_android_frame_bolt" : Battery.percentage >= 95 ? "battery_android_frame_full" : bars > 0 ? `battery_android_frame_${bars}` : "battery_android_0"

    property real shown: Battery.percentage / 100
    Behavior on shown {
        K.Anim {
            type: K.Anim.DefaultEffects
        }
    }

    visible: Battery.available
    implicitWidth: Battery.available && !levelHidden ? (view.item?.implicitWidth ?? 0) : 0
    implicitHeight: 24

    Loader {
        id: view
        anchors.verticalCenter: parent.verticalCenter
        active: !root.levelHidden
        sourceComponent: root.style === "ring" || root.style === "arc" ? ring : marked
    }

    component Number: CapText {
        height: 12
        pixelSize: 11
        weight: 700
    }

    // the Quick configs' mark: plugged in = on (charging, full or held at a charge limit: the charging look
    // whenever the charger is in, user 2026-10-15), low = the error colour
    QtObject {
        id: markModel
        readonly property string symbol: root.symbol
        readonly property bool active: Battery.pluggedIn
        readonly property bool danger: Battery.low
    }

    Component {
        id: marked
        Row {
            spacing: 4

            DQ.QMark {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showIcon
                width: 22
                height: 22
                q: markModel
                look: root.style
                pal: root.pal
                tone: colors.tone
                overTone: colors.overTone
                weight: root.style === "tones" ? 600 : 400
                iconSize: 14
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showText

                Number {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.number
                    weight: root.style === "tone" ? (Battery.pluggedIn ? 700 : 500) : root.style === "tones" ? 700 : 600
                    color: root.style === "shapes" ? (Battery.low ? Colors.error : root.pal.over) : root.tone
                }
                Number {
                    anchors.verticalCenter: parent.verticalCenter
                    // Two tones: "%" in the weak tone; the others only without the mark
                    visible: root.style === "tones" || !root.showIcon
                    text: "%"
                    weight: root.style === "tones" ? 500 : 600
                    color: root.style === "tones" ? Qt.alpha(root.tone, 0.55) : root.style === "shapes" ? (Battery.low ? Colors.error : root.pal.over) : root.tone
                }
            }
        }
    }

    // the ring alone (icon), the number alone (text), or the number in the ring (both); Arc without the
    // ring's track
    Component {
        id: ring
        Item {
            implicitWidth: root.showIcon ? 24 : alone.implicitWidth
            implicitHeight: 24

            K.WavyRing {
                anchors.fill: parent
                visible: root.showIcon
                value: root.shown
                wavy: Battery.pluggedIn
                thickness: 2
                amplitude: 0.8
                waves: 12
                activeColor: root.tone
                inactiveColor: root.style === "arc" ? "transparent" : Qt.alpha(root.tone, 0.25)
            }
            CapText {
                anchors.centerIn: parent
                visible: root.showIcon && root.showText
                height: 8
                text: root.number
                pixelSize: 8
                weight: 700
                color: root.pal.over
            }
            Number {
                id: alone
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.showIcon
                text: root.number + "%"
                color: Battery.low ? Colors.error : root.pal.over
            }
        }
    }
}
