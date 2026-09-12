import QtQuick
import Quickshell
import Quickshell.Bluetooth
import ".."
import "../../../Config"

// ═══════════════════════════════════════════
//  BLUETOOTH DETAIL — Lista de dispositivos; clique conecta ou
//  desconecta. Pareamento novo continua no app externo (o diálogo de
//  confirmação do BlueZ não vale o escopo aqui).
// ═══════════════════════════════════════════
DashDetail {
    id: root

    name: "bluetooth"
    title: "Bluetooth"
    actionIcon: "" // abre o app completo

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false

    // Conectados primeiro, pareados depois, então o resto por nome
    readonly property var devices: {
        return [...Bluetooth.devices.values].sort((a, b) =>
            (b.connected - a.connected)
            || (b.paired - a.paired)
            || (a.name ?? "").localeCompare(b.name ?? ""))
    }

    // Descoberta só enquanto a tela está à mostra: o rádio varrendo
    // com o detalhe fechado é bateria à toa
    onVisibleChanged: if (adapter) adapter.discovering = visible

    onAction: Quickshell.execDetached([Config.bluetoothApp])

    Column {
        width: parent.width
        spacing: 2

        Text {
            visible: root.devices.length === 0
            text: root.on ? "Procurando dispositivos…" : "Bluetooth desligado"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        Repeater {
            model: root.devices

            DetailRow {
                required property var modelData

                label: modelData.name || modelData.address
                current: modelData.connected
                value: modelData.connected ? "conectado"
                     : (modelData.paired ? "pareado" : "")
                // Pareado mas desconectado ainda é "conhecido": o ícone
                // separa isso de um dispositivo que só apareceu no ar
                icon: modelData.paired ? "󰂱" : "󰂯"

                onTapped: {
                    if (modelData.connected)
                        modelData.disconnect()
                    else
                        modelData.connect()
                }
            }
        }
    }
}
