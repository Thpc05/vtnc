import QtQuick
import qs.base.core
import qs.base.services
import qs.base.theme
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
