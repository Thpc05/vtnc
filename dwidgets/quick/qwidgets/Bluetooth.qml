import QtQuick
import qs.services
import qs.theme
import ".."
import "../panels"

Qwidget {
    readonly property var device: BluetoothService.friendlyDeviceList.find(d => d.connected) ?? null

    title: "Bluetooth"
    symbol: !BluetoothService.enabled ? "bluetooth_disabled" : (BluetoothService.connected ? "bluetooth_connected" : "bluetooth")
    icon: !BluetoothService.enabled ? Icons.bluetoothOff : (BluetoothService.connected ? Icons.bluetoothConnected : Icons.bluetooth)
    active: BluetoothService.enabled
    status: !BluetoothService.enabled ? "Off" : (device ? device.name : "On")
    action: ({
            icon: "refresh",
            run: () => BluetoothService.startDiscovery()
        })
    panel: Component {
        BluetoothPanel {}
    }

    function toggle() {
        BluetoothService.toggle();
    }

    Component.onCompleted: BluetoothService.initialize()
}
