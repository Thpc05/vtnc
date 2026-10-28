import QtQuick
import qs.services
import qs.theme
import ".."
import "../panels"

Qwidget {
    title: "Wi-Fi"
    symbol: !NetworkService.wifiEnabled ? "wifi_off" : NetworkService.networkName === "" ? "signal_wifi_0_bar" : "wifi"
    icon: {
        if (!NetworkService.wifiEnabled)
            return Icons.wifiOff;
        if (NetworkService.networkName === "")
            return Icons.wifiNone;
        return NetworkService.networkStrength > 0 ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiHigh;
    }
    active: NetworkService.wifiEnabled
    status: !NetworkService.wifiEnabled ? "Off" : (NetworkService.wifiConnecting ? "Connecting…" : (NetworkService.networkName || "Disconnected"))
    action: ({
            icon: "refresh",
            run: () => NetworkService.rescanWifi()
        })
    panel: Component {
        WifiPanel {}
    }

    function toggle() {
        NetworkService.toggleWifi();
    }
}
