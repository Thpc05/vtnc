import QtQuick
import qs.services
import ".."

Swidget {
    readonly property var node: Audio.source?.audio ?? null

    value: node?.volume ?? 0
    muted: node?.muted ?? false
    ready: node !== null
    symbol: muted ? "mic_off" : "mic"

    function set(v) {
        if (node)
            node.volume = Math.min(1, v);
    }
    function iconClicked() {
        Audio.toggleMicMute();
    }
}
