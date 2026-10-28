pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property var lastScanTime: 0
    property bool wifiConnecting: isUpdating && wifiStatus === "connecting"
    property bool isUpdating: false
    property bool wasEnabledBeforeSleep: false

    property var suspendConnections: Connections {
        target: SuspendManager
        function onPreparingForSleep() {
            root.wasEnabledBeforeSleep = root.wifiEnabled;
        }
        function onWakingUp() {
            if (root.wasEnabledBeforeSleep) {
                root.enableWifi(true);
            }
        }
    }

    property WifiAccessPoint wifiConnectTarget: null
    readonly property list<WifiAccessPoint> wifiNetworks: []
    property WifiAccessPoint active: null

    function updateActive() {
        for (let i = 0; i < wifiNetworks.length; i++) {
            if (wifiNetworks[i].active) {
                active = wifiNetworks[i];
                return;
            }
        }
        active = null;
    }

    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength: 0

    property list<var> friendlyWifiNetworks: []

    function updateFriendlyList() {
        friendlyWifiNetworks = [...wifiNetworks].sort((a, b) => {
            if (a.active && !b.active)
                return -1;
            if (!a.active && b.active)
                return 1;
            return b.strength - a.strength;
        });
        updateActive();
    }

    function enableWifi(enabled = true): void {
        isUpdating = true;
        root.backendCall("network.enable", {enabled: enabled}, (result, error) => {
            if (result) applyState(result);
            isUpdating = false;
        });
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        const now = Date.now();
        if (now - lastScanTime < 10000) { // 10s throttle
            requestNetworks();
            return;
        }

        lastScanTime = now;
        wifiScanning = true;
        // Daemon rescan: disable+enable wifi briefly triggers a scan; simpler to
        // just re-list now and mark scanning false.
        requestNetworks();
        wifiScanning = false;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        isUpdating = true;
        root.backendCall("network.connect", {ssid: accessPoint.ssid}, (result, error) => {
            if (error) {
                accessPoint.askingPassword = true;
            } else if (result && result.need_password) {
                accessPoint.askingPassword = true;
            }
            root.wifiConnectTarget = null;
            isUpdating = false;
            requestNetworks();
        });
    }

    function disconnectWifiNetwork(): void {
        if (active) {
            isUpdating = true;
            root.backendCall("network.disconnect", {ssid: active.ssid}, (result, error) => {
                isUpdating = false;
                requestNetworks();
            });
        }
    }

    function changePassword(network: WifiAccessPoint, password: string): void {
        network.askingPassword = false;
        isUpdating = true;
        root.backendCall("network.connect", {ssid: network.ssid, password: password}, (result, error) => {
            isUpdating = false;
            requestNetworks();
        });
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    // WiFi icon by strength
    function wifiIconForStrength(strength: int): string {
        if (strength > 80) return Icons.wifiHigh;
        if (strength > 55) return Icons.wifiMedium;
        if (strength > 30) return Icons.wifiLow;
        if (strength > 0) return Icons.wifiNone;
        return Icons.wifiOff;
    }

    function applyState(state) {
        if (!state) return;
        root.wifi = state.wifi;
        root.ethernet = state.ethernet;
        root.wifiEnabled = state.wifi_enabled;
        root.wifiStatus = state.wifi_status;
        root.networkName = state.network_name;
        root.networkStrength = state.strength || 0;
        root.isUpdating = false;
    }

    function requestNetworks() {
        root.backendCall("network.networks", {}, (result, error) => {
            if (error || !result) return;
            const inData = result;
            Qt.callLater(() => root.syncNetworks(inData));
        });
    }

    function updateStatus() {
        root.backendCall("network.status", {}, (result, error) => {
            if (result) root.applyState(result);
        });
    }

    // Update status
    Timer {
        id: updateDebouncer
        interval: 200
        repeat: false
        onTriggered: root.updateStatus()
    }

    function update() {
        updateDebouncer.restart();
    }

    function syncNetworks(wifiNetworksData) {
        const rNetworks = root.wifiNetworks;
        // 1. Remove gone networks
        for (let i = rNetworks.length - 1; i >= 0; i--) {
            const rn = rNetworks[i];
            const found = wifiNetworksData.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid);
            if (!found) {
                rNetworks.splice(i, 1);
                rn.destroy();
            }
        }

        // 2. Add/update networks
        for (let i = 0; i < wifiNetworksData.length; i++) {
            const data = wifiNetworksData[i];
            const existing = rNetworks.find(n => n.frequency === data.frequency && n.ssid === data.ssid && n.bssid === data.bssid);
            if (existing) {
                existing.lastIpcObject = data;
            } else {
                rNetworks.push(apComp.createObject(root, {
                    lastIpcObject: data
                }));
            }
        }

        root.updateFriendlyList();
    }

    // vtnc: backed by scripts/network.py (nmcli, JSON output).
    readonly property string helper: Qt.resolvedUrl("../scripts/network.py").toString().replace("file://", "")

    function backendCall(method, params, callback) {
        const name = method.replace("network.", "");
        let args = [];
        if (name === "enable")
            args = [params.enabled ? "true" : "false"];
        else if (name === "connect")
            args = [params.ssid, params.password ?? ""];
        else if (name === "disconnect")
            args = [params.ssid];
        const proc = callComp.createObject(root, {
            command: [root.helper, name, ...args],
            callback: callback
        });
        proc.running = true;
    }

    Component {
        id: callComp
        Process {
            id: proc
            property var callback
            stdout: StdioCollector {
                onStreamFinished: {
                    let result = null;
                    try {
                        result = JSON.parse(text);
                    } catch (e) {}
                    if (result && result.error)
                        proc.callback?.(null, result.error);
                    else
                        proc.callback?.(result, result ? null : "invalid output");
                    proc.destroy();
                }
            }
        }
    }

    // network.state stream (replaces the daemon subscription): one status line per nmcli monitor event
    Process {
        running: true
        command: [root.helper, "monitor"]
        stdout: SplitParser {
            onRead: line => {
                let data = null;
                try {
                    data = JSON.parse(line);
                } catch (e) {
                    return;
                }
                if (!root.isUpdating)
                    Qt.callLater(() => root.applyState(data));
            }
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }

    Component.onCompleted: {
        updateStatus();
        requestNetworks();
    }
}
