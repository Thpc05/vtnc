import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import ".."
import "../../../Config"
import "../../../Ui"

// ═══════════════════════════════════════════
//  NETWORK DETAIL — Lista de redes, cabo e senha.
//  Restaura o que o widget antigo fazia e a Fase 4 tinha derrubado.
// ═══════════════════════════════════════════
DashDetail {
    id: root

    name: "network"
    title: "Wi-Fi"
    actionIcon: "" // lupa: força um rescan

    readonly property bool on: Networking.wifiEnabled
    readonly property var wifiDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var lanDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wired)
    readonly property bool lanUp:
        (lanDevice?.state ?? 0) === ConnectionState.Connected

    // Conectada primeiro, conhecidas depois, então por sinal
    readonly property var networks: {
        if (!wifiDevice)
            return []
        return [...wifiDevice.networks.values]
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected)
                || (b.known - a.known)
                || (b.signalStrength - a.signalStrength))
    }

    // ARMADILHA: o Quickshell só popula `networks` com o scanner DELE
    // ligado — um `nmcli rescan` sozinho não enche a lista. Liga só
    // enquanto o detalhe está à mostra: deixar o rádio varrendo com a
    // tela fechada é custo puro
    readonly property bool scanning: visible
    onScanningChanged: if (wifiDevice) wifiDevice.scannerEnabled = scanning

    Process { id: wifiScan }
    Process { id: wifiConnect }

    onAction: {
        wifiScan.command = ["nmcli", "device", "wifi", "rescan"]
        wifiScan.running = true
    }

    // ── SENHA: rede protegida e desconhecida ──
    property string passSsid: ""
    onVisibleChanged: if (!visible) passSsid = ""

    Timer {
        id: focoSenha
        interval: 150 // espera o compositor entregar o teclado
        onTriggered: campoSenha.forceActiveFocus()
    }

    function conectarComSenha() {
        if (campoSenha.text === "" || passSsid === "")
            return
        // argv separado, sem shell: SSID com espaço ou aspas não quebra
        wifiConnect.command = ["nmcli", "device", "wifi", "connect",
                               passSsid, "password", campoSenha.text]
        wifiConnect.running = true
        campoSenha.text = ""
        passSsid = ""
    }

    // ── CABO ──
    DetailRow {
        visible: root.lanUp
        height: root.lanUp ? 26 : 0
        icon: "󰈀"
        label: root.lanDevice?.name ?? "Cabo"
        value: "conectado"
        current: true
    }

    // ── CAMPO DE SENHA (toma o lugar da lista) ──
    Column {
        width: parent.width
        spacing: 5
        visible: root.passSsid !== ""

        Text {
            text: "senha · " + root.passSsid
            width: parent.width
            elide: Text.ElideRight
            color: Theme.textSecondary
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        Rectangle {
            width: parent.width
            height: 26
            radius: Theme.radiusChip
            color: Theme.hoverLayer

            TextInput {
                id: campoSenha

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.textPrimary
                selectionColor: Theme.accent
                clip: true
                font { family: Theme.fontMono; pixelSize: 11 }

                onAccepted: root.conectarComSenha()
                Keys.onEscapePressed: root.passSsid = ""
            }
        }

        Text {
            text: "Enter conecta · Esc cancela"
            color: Theme.textMuted
            font { family: Theme.fontMono; pixelSize: 9 }
        }
    }

    // ── LISTA DE REDES ──
    Column {
        width: parent.width
        spacing: 2
        visible: root.passSsid === ""

        Text {
            visible: root.networks.length === 0
            text: root.on ? "Procurando redes…" : "Wi-Fi desligado"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        Repeater {
            model: root.networks

            DetailRow {
                required property var modelData

                label: modelData.name
                value: Math.round(modelData.signalStrength * 100) + "%"
                current: modelData.connected
                // Cadeado só em rede protegida que ainda não é conhecida:
                // o que ele comunica é "vai pedir senha"
                icon: (modelData.security !== 0 && !modelData.known) ? "󰌾" : ""

                onTapped: {
                    if (modelData.connected)
                        modelData.requestDisconnect()
                    else if (modelData.known || modelData.security === 0)
                        modelData.requestConnect()
                    else {
                        root.passSsid = modelData.name
                        focoSenha.restart()
                    }
                }
            }
        }
    }
}
