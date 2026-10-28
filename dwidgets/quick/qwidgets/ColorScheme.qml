import QtQuick
import qs.core
import qs.services
import qs.theme
import ".."
import "../panels"

// matugen's scheme, one step per click (a right click goes back); the colours regenerate
// (Wallpapers.cycleScheme; IPC `scheme`). An action: no on / off.
Qwidget {
    title: "Color scheme"
    symbol: "palette"
    icon: Icons.palette
    status: (Store.theme.scheme || "").replace("scheme-", "").split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
    alternate: () => Wallpapers.cycleScheme(-1)
    switchable: false
    panel: Component {
        SchemePanel {}
    }

    function toggle() {
        Wallpapers.cycleScheme(1);
    }
}
