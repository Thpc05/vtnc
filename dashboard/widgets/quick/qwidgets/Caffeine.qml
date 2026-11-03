import QtQuick
import qs.base.services
import qs.base.theme
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
