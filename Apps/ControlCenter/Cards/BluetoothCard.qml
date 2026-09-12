import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "."
import "../../../ConfigValues"

// ═══════════════════════════════════════════
//  BLUETOOTH CARD — Estado do adapter; o corpo liga/desliga.
//  FALTA a lista de dispositivos (ver a nota no WifiCard).
// ═══════════════════════════════════════════
ToggleCard {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var connectedDevs:
        Bluetooth.devices.values.filter(d => d.connected)

    lit: on
    title: "Bluetooth"

    status: {
        if (!on)
            return "Desligado"
        if (connectedDevs.length === 0)
            return "Nenhum conectado"
        // Um conectado: mostra o nome. Vários: mostra a conta, porque
        // dois nomes cortados não informam nada
        return connectedDevs.length === 1
            ? (connectedDevs[0].name ?? connectedDevs[0].address)
            : connectedDevs.length + " conectados"
    }

    icon: !on ? "󰂲" : (connectedDevs.length > 0 ? "󰂱" : "󰂯")

    onTapped: if (adapter) adapter.enabled = !adapter.enabled
}
