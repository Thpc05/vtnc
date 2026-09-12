import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "."
import "../../Config"

// ═══════════════════════════════════════════
//  WIFI CARD — Estado do Wi-Fi; o corpo liga/desliga.
//
//  FALTA a lista de redes e o campo de senha, que o widget antigo
//  tinha. Eles vão numa tela de DETALHE (o DashCard já tem o gancho
//  `detail`), ainda não escrita — por isso `detail` está vazio aqui:
//  chevron sem destino seria pior que chevron nenhum.
// ═══════════════════════════════════════════
ToggleCard {
    id: root

    readonly property bool on: Networking.wifiEnabled
    readonly property var wifiDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var activeNet: wifiDevice
        ? wifiDevice.networks.values.find(n => n.connected)
        : null
    readonly property real netSignal: activeNet ? activeNet.signalStrength : 0

    // LAN (cabo): entra no status quando não há Wi-Fi conectado —
    // dizer "Desconectado" com o cabo na tomada seria mentira
    readonly property var lanDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wired)
    readonly property bool lanUp:
        (lanDevice?.state ?? 0) === ConnectionState.Connected

    lit: on
    title: "Wi-Fi"

    status: {
        if (activeNet)
            return activeNet.name
        if (lanUp)
            return "Cabo conectado"
        return on ? "Desconectado" : "Desligado"
    }

    icon: {
        if (!on)
            return String.fromCodePoint(0xF05AA)
        if (!activeNet)
            return String.fromCodePoint(0xF092D)
        // Os glyphs de força vêm de 3 em 3 no bloco do Nerd Font
        const tier = netSignal >= 0.75 ? 4
                   : netSignal >= 0.50 ? 3
                   : netSignal >= 0.25 ? 2
                   : 1
        return String.fromCodePoint(0xF091F + (tier - 1) * 3)
    }

    Process { id: wifiToggle }

    onTapped: {
        wifiToggle.command = ["nmcli", "radio", "wifi", on ? "off" : "on"]
        wifiToggle.running = true
    }
}
