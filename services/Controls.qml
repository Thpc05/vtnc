pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.core

// Quick controls: wifi, bluetooth, night light (wlsunset), caffeine, game mode.
Singleton {
    id: root

    // wifi / bluetooth (native Quickshell modules)
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifiNetwork: {
        for (const d of Networking.devices.values)
            for (const n of d.networks?.values ?? [])
                if (n.connected)
                    return n;
        return null;
    }
    readonly property BluetoothAdapter btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: btAdapter !== null
    readonly property bool btEnabled: btAdapter?.enabled ?? false
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth() {
        if (btAdapter)
            btAdapter.enabled = !btAdapter.enabled;
    }

    // night light: persistent (Store.controls), constant temperature
    readonly property bool nightLight: Store.controls.nightLight

    function toggleNightLight() {
        Store.controls.nightLight = !Store.controls.nightLight;
    }

    Process {
        id: nightLightProc
        running: Store.ready && root.nightLight
        command: ["wlsunset", "-t", String(Store.nightLight.temp - 1), "-T", String(Store.nightLight.temp)]
    }

    // vtnc: wlsunset only reads the temperature at start: restart it when it changes while on
    // (debounced, so stepping through values doesn't respawn it on every step)
    Connections {
        target: Store.nightLight
        function onTempChanged() {
            if (root.nightLight)
                nightLightRestart.restart();
        }
    }
    Timer {
        id: nightLightRestart
        interval: 400
        onTriggered: {
            nightLightProc.running = false;
            Qt.callLater(() => nightLightProc.running = Qt.binding(() => Store.ready && root.nightLight));
        }
    }

    // caffeine: IdleInhibitor lives in IslandWindow (it needs a window); persistent
    readonly property bool caffeine: Store.controls.caffeine

    function toggleCaffeine() {
        Store.controls.caffeine = !Store.controls.caffeine;
    }

    // game mode: Hyprland without animations / blur / shadows; `hyprctl reload` restores the config
    // persistent; re-applied when the shell starts (e.g. after restarting Hyprland)
    readonly property bool gameMode: Store.controls.gameMode

    function toggleGameMode() {
        Store.controls.gameMode = !Store.controls.gameMode;
        applyGameMode();
    }

    function applyGameMode() {
        if (gameMode)
            Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } } })"]);
        else
            Quickshell.execDetached(["hyprctl", "reload"]);
    }

    // do-not-disturb (Notifications.silent) is kept in Store.controls.dnd
    function syncDnd() {
        Notifications.silent = Store.controls.dnd;
    }

    Connections {
        target: Notifications
        function onSilentChanged() {
            if (Store.ready && Store.controls.dnd !== Notifications.silent)
                Store.controls.dnd = Notifications.silent;
        }
    }

    Connections {
        target: Store.controls
        function onDndChanged() {
            root.syncDnd();
        }
    }

    Connections {
        target: Store
        function onReadyChanged() {
            if (Store.ready)
                root.restore();
        }
    }
    Component.onCompleted: if (Store.ready)
        restore()

    function restore() {
        syncDnd();
        if (gameMode)
            applyGameMode();
    }
}
