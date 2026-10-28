import QtQuick
import qs.services
import ".."

Swidget {
    readonly property var node: Audio.sink?.audio ?? null

    value: node?.volume ?? 0
    muted: node?.muted ?? false
    ready: node !== null
    symbol: muted ? "volume_off" : value < 0.01 ? "volume_mute" : value < 0.5 ? "volume_down" : "volume_up"

    function set(v) {
        if (node)
            node.volume = Math.min(Audio.maxValue, v);
    }
    function iconClicked() {
        Audio.toggleMute();
    }
}
