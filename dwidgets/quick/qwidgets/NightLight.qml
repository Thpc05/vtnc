import QtQuick
import qs.core
import qs.services
import qs.theme
import ".."
import "../panels"

Qwidget {
    // the night light, named by what it sets (the screen's color temperature)
    title: "Temperature"
    symbol: "device_thermostat"
    icon: Icons.thermometer
    active: NightLightClient.active
    status: active ? Store.nightLight.temp + " K" : "Off"
    panel: Component {
        NightLightPanel {}
    }

    function toggle() {
        NightLightClient.toggle();
    }
}
