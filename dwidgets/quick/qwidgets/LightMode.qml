import QtQuick
import qs.core
import qs.theme
import ".."

Qwidget {
    title: "Light mode"
    symbol: Store.theme.light ? "light_mode" : "dark_mode"
    icon: Store.theme.light ? Icons.sun : Icons.moon
    active: Store.theme.light
    status: Store.theme.light ? "Light" : "Dark"

    function toggle() {
        Store.theme.light = !Store.theme.light;
    }
}
