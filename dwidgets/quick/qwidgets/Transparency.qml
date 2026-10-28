import QtQuick
import qs.core
import qs.theme
import ".."

// Transparent surfaces on / off (Appearance → Transparency; IPC `transparency`)
Qwidget {
    title: "Transparency"
    symbol: "opacity"
    icon: Icons.transparency
    active: Store.theme.transparency.enabled

    function toggle() {
        Store.theme.transparency.enabled = !Store.theme.transparency.enabled;
    }
}
