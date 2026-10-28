import QtQuick
import qs.services
import qs.theme
import ".."

Qwidget {
    readonly property bool muted: Audio.source?.audio?.muted ?? false

    title: "Microphone"
    symbol: muted ? "mic_off" : "mic"
    icon: muted ? Icons.micSlash : Icons.mic
    available: Audio.source !== null
    active: available && !muted
    status: !available ? "No mic" : (muted ? "Muted" : "On")

    function toggle() {
        if (Audio.source?.audio)
            Audio.source.audio.muted = !Audio.source.audio.muted;
    }
}
