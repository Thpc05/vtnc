import QtQuick
import qs.services
import qs.theme
import ".."
import "../panels"

// The output's state; a click opens its panel, the mixer (devices and a volume per app). It
// doesn't mute.
Qwidget {
    readonly property var node: Audio.sink?.audio ?? null
    readonly property bool muted: node?.muted ?? false

    title: "Mixer"
    symbol: muted ? "volume_off" : "tune"
    icon: Icons.faders
    available: Audio.sink !== null
    active: available && !muted
    status: !available ? "No output" : muted ? "Muted" : Audio.friendlyDeviceName(Audio.sink)
    opensPanel: true
    panel: Component {
        MixerPanel {}
    }

    function toggle() {
    }
}
