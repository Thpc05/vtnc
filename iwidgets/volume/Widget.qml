import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.kit as K
import qs.dwidgets

// The output volume (stage 7, 2026-10-08; one style since 2026-10-11, user). The wheel changes it
// everywhere. The slider: a thin K.M3Slider (dragging sets the volume), with per island mode
// (island.volume.<mode>) the speaker icon before it (a click mutes) and the percent after it; the
// slider waves while music plays (island.volume.wavy). Also on the island card (the Card variant: `pal`),
// and the volume OSD as a widget (osd.volumeWidget). The old pill / Icon + slider / Slider migrate.
Item {
    id: root

    property string style: "slider"
    // from the frame: the island mode and the palette (the island card's, or the bare island's)
    property string mode: "compact"
    property var pal: K.Kit.bare
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property real level: Math.min(1, Audio.value)
    readonly property string percent: Math.round(Audio.value * 100)
    readonly property bool showIcon: Store.island.volume?.[mode]?.icon ?? true
    readonly property bool showPercent: Store.island.volume?.[mode]?.percent ?? true
    readonly property bool wavy: (Store.island.volume?.wavy ?? true) && MprisController.isPlaying && !muted

    implicitWidth: row.implicitWidth
    implicitHeight: 24

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => Audio.setVolume(Audio.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)) // setVolume applies the limit
    }

    // the island's number standard (the battery's): Rubik 11 bold, its cap height centred (2026-10-15; was
    // the UI font 600, centred on the line box: ~1.5 px high)
    TextMetrics {
        id: threeDigits
        font.family: K.Kit.clockFamily
        font.pixelSize: 11
        font.weight: 700
        font.features: ({
                "tnum": 1
            })
        text: "000"
    }
    component Number: CapText {
        text: root.percent
        height: 12
        pixelSize: 11
        weight: 700
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: K.Kit.spacing.small

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showIcon
            width: 20
            height: 20
            K.StateLayer {
                radius: width / 2
                color: root.pal.over
                onClicked: Audio.toggleMute()
            }
            K.MaterialIcon {
                x: Math.round((parent.width - width) / 2)
                y: Math.round((parent.height - height) / 2)
                text: Audio.volumeIcon(Audio.value, root.muted)
                size: 18
                fill: root.muted ? 0 : 1
                color: root.muted ? Colors.error : root.pal.over
            }
        }
        K.M3Slider {
            anchors.verticalCenter: parent.verticalCenter
            // alone a little longer (the old Slider style)
            width: root.showIcon || root.showPercent ? 64 : 80
            height: 16
            vertical: false
            trackThickness: 4
            inactiveThickness: 4
            wavy: root.wavy
            handleShape: wavy ? "circle" : "bar"
            waveAmplitude: 2
            wavelength: 14
            muted: root.muted
            activeColor: root.pal.accent
            // the rest: the palette's track, but in light a tint of the accent (secondaryContainer all but
            // vanished on the light island)
            inactiveColor: K.Kit.expressive.light ? Qt.alpha(root.pal.accent, 0.3) : root.pal.track
            value: root.level
            onMoved: v => Audio.setVolume(v)
        }
        Number {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showPercent
            // as wide as three digits (100 or up to the limit's 150; the row doesn't shift as it changes)
            width: Math.ceil(threeDigits.advanceWidth)
            color: root.pal.overVariant
        }
    }
}
