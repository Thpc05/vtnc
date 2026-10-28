import QtQuick
import qs.core
import qs.services
import ".."

// The warmth: 6500 K (0) to 2500 K (1), in 100 K steps; dimmed while the
// night light is off. The icon turns it on / off.
Swidget {
    readonly property int temp: Store.nightLight.temp

    value: (6500 - temp) / 4000
    muted: !NightLightClient.active
    symbol: "nightlight"
    iconFill: NightLightClient.active ? 1 : 0

    function set(v) {
        Store.nightLight.temp = Math.round((6500 - v * 4000) / 100) * 100;
    }
    function iconClicked() {
        NightLightClient.toggle();
    }
}
