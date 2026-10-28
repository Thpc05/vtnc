import QtQuick
import qs.services
import qs.theme
import ".."

Qwidget {
    title: "Caffeine"
    symbol: "coffee"
    icon: Icons.caffeine
    active: CaffeineClient.inhibit

    function toggle() {
        CaffeineClient.toggle();
    }
}
