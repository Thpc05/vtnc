import QtQuick
import qs.services
import qs.kit as K

// One column of the Mixer panel (2026-10-17, user: output and input side by side): the default device on
// top (PanelHero, compact: name, volume, a slider; the mark mutes), then the devices (a click makes one
// the default). `sink`: the output, else the input.
Column {
    id: col

    property var look: null
    readonly property PanelColors c: PanelColors {
        look: col.look
    }
    property bool sink: true
    readonly property var node: sink ? Audio.sink : Audio.source
    readonly property var audio: node?.audio ?? null

    PanelHero {
        id: hero
        width: col.width
        look: col.look
        markSize: 32
        active: !(col.audio?.muted ?? false)
        symbol: col.sink ? (col.audio?.muted ? "volume_off" : "speaker") : (col.audio?.muted ? "mic_off" : "mic")
        title: col.node ? Audio.friendlyDeviceName(col.node) : (col.sink ? "No output" : "No input")
        subtitle: col.audio?.muted ? "Muted" : Math.round((col.audio?.volume ?? 0) * 100) + "%"
        extraHeight: 16

        K.M3Slider {
            anchors.fill: parent
            vertical: false
            trackThickness: 6
            activeColor: col.c.accent
            inactiveColor: col.c.off
            value: col.audio?.volume ?? 0
            muted: col.audio?.muted ?? false
            onMoved: v => {
                if (col.audio)
                    col.audio.volume = v;
            }
        }
        // the mark mutes
        MouseArea {
            width: hero.markSize
            height: width
            y: -(width + 8)
            cursorShape: Qt.PointingHandCursor
            onClicked: if (col.audio)
                col.audio.muted = !col.audio.muted
        }
    }
    PanelSection {
        width: col.width
        look: col.look
        text: col.sink ? "Output" : "Input"
    }
    Repeater {
        model: col.sink ? Audio.outputDevices : Audio.inputDevices
        PanelRow {
            required property var modelData
            width: col.width
            headHeight: 32
            look: col.look
            current: modelData === col.node
            icon: col.sink ? "speaker" : "mic"
            title: Audio.friendlyDeviceName(modelData)
            onClicked: col.sink ? Audio.setDefaultSink(modelData) : Audio.setDefaultSource(modelData)
        }
    }
}
