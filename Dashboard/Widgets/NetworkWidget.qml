import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import ".."
import "../../Config"

// ═══════════════════════════════════════════
//  NETWORK WIDGET — Wi-Fi e LAN.
//  Idle: ícone (toggle wifi) + SSID conectado.
//  Expandido: linha da LAN, lupa (rescan), app externo, campo de
//  senha (redes protegidas desconhecidas) e a lista de redes.
//
//  TODO: expansão lateral prevista e DESLIGADA. O plano era
//  `sizeExpand: "big"` + `expandDir: "down-right"`; hoje é
//  normal/down, então a lista de redes vive em 2 subcolunas e os
//  SSIDs cortam cedo.
//
//  Tamanhos: small/normal → normal/big · direções: down,
//  down-left, down-right.
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "network"
    sizeIdle: "normal"   // Small and Normal
    sizeExpand: "normal" // Normal and Big
    expandDir: "down"    // down, down-left and down-right

    readonly property bool on: Networking.wifiEnabled
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var activeNet: wifiDevice
        ? wifiDevice.networks.values.find(n => n.connected)
        : null
    readonly property real netSignal: activeNet ? activeNet.signalStrength : 0

    // LAN (cabo): device Wired + estado conectado
    readonly property var lanDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired)
    readonly property bool lanUp: (lanDevice?.state ?? 0) === ConnectionState.Connected

    readonly property string icon: {
        if (!on) return String.fromCodePoint(0xF05AA)
        if (!activeNet) return String.fromCodePoint(0xF092D)

        const tier = netSignal >= 0.75 ? 4
                   : netSignal >= 0.50 ? 3
                   : netSignal >= 0.25 ? 2
                   : 1
        return String.fromCodePoint(0xF091F + (tier - 1) * 3)
    }

    Process { id: wifiToggle }
    Process { id: wifiScan }
    Process { id: wifiConnect }

    // ── SENHA: rede desconhecida protegida aguardando senha ──
    property string passSsid: ""
    // Pede o teclado pra shell enquanto o campo está vivo
    wantsKeyboard: passSsid !== "" && expanded

    onExpandedChanged: {
        if (!expanded)
            passSsid = ""
    }

    Timer {
        id: passFocusTimer
        interval: 150 // espera o compositor entregar o teclado
        onTriggered: passInput.forceActiveFocus()
    }

    function connectWithPass() {
        if (passInput.text === "" || passSsid === "")
            return
        // argv separado: sem shell, sem problema de quoting no SSID
        wifiConnect.command = ["nmcli", "device", "wifi", "connect",
            passSsid, "password", passInput.text]
        wifiConnect.running = true
        passInput.text = ""
        passSsid = ""
    }

    // Redes visíveis: conectada primeiro, conhecidas depois, então sinal
    readonly property var networks: {
        if (!wifiDevice) return []
        return [...wifiDevice.networks.values]
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected)
                || (b.known - a.known)
                || (b.signalStrength - a.signalStrength))
    }

    // O Quickshell SÓ rastreia redes visíveis com o scanner dele
    // ligado (rescan do nmcli sozinho não popula `networks`).
    // Liga enquanto expandido E visível — pinado com dashboard
    // fechada não pode deixar o rádio escaneando pra sempre
    readonly property bool scanning: expanded && visible
    onScanningChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = scanning
    }

    // ── HEADER: ícone (clique liga/desliga, com mira) + dado ──
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerH

        Item {
            width: 24
            height: 22
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: iconHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.expanded ? Theme.accent : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 16 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            HoverHandler { id: iconHover }
            TapHandler {
                onTapped: {
                    wifiToggle.command = ["nmcli", "radio", "wifi", root.on ? "off" : "on"]
                    wifiToggle.running = true
                }
            }
        }

        // Dado: rede conectada (some ao expandir — dá lugar aos botões)
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.activeNet?.name ?? ""
            color: Theme.textSecondary
            width: Math.min(implicitWidth, 58)
            elide: Text.ElideRight
            opacity: 1 - root.lateReveal
            visible: opacity > 0
            font { family: Theme.fontDisplay; pixelSize: 10 }
        }

        // ── EXPANDIDO: lupa (rescan) + app, no lugar do dado ──
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            opacity: root.lateReveal
            visible: opacity > 0

            Item {
                width: 18
                height: 18

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: scanHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    color: scanHover.hovered ? Theme.textPrimary : Theme.textMuted
                    font { family: Theme.fontIcon; pixelSize: 12 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: scanHover }
                TapHandler {
                    onTapped: {
                        wifiScan.command = ["nmcli", "device", "wifi", "rescan"]
                        wifiScan.running = true
                    }
                }
            }

            Item {
                width: 18
                height: 18

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: appHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: appHover.hovered ? Theme.textPrimary : Theme.textMuted
                    font { family: Theme.fontIcon; pixelSize: 10 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: appHover }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: Quickshell.execDetached([Config.networkApp])
                }
            }
        }
    }

    // ── EXPANDIDO: actualLan — ícone + nome da LAN, logo abaixo do
    //  ícone de wifi (entre ele e a lista de redes). SÓ aparece
    //  quando há cabo conectado; some (altura 0) quando não. ──
    Item {
        id: lanRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.headerH
        height: root.lanUp ? 22 : 0
        opacity: root.lateReveal
        visible: opacity > 0 && root.lanUp

        Item {
            id: lanIconBox
            width: 24
            height: parent.height
            anchors.left: parent.left

            Text {
                anchors.centerIn: parent
                text: "󰈀"
                color: Theme.accent
                font { family: Theme.fontIcon; pixelSize: 14 }
            }
        }

        Text {
            anchors.left: lanIconBox.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.lanDevice?.name ?? "LAN"
            color: Theme.textSecondary
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }
    }

    // ── EXPANDIDO: campo de senha (toma o lugar da lista) ──
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        spacing: 6
        opacity: root.lateReveal
        visible: opacity > 0 && root.passSsid !== ""

        Text {
            text: `senha · ${root.passSsid}`
            color: Theme.textSecondary
            width: parent.width
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: Theme.surface

            TextInput {
                id: passInput

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.textPrimary
                clip: true
                font { family: Theme.fontMono; pixelSize: 11 }

                onAccepted: root.connectWithPass()
                Keys.onEscapePressed: root.passSsid = ""
            }
        }

        Text {
            text: "Enter conecta · Esc cancela"
            color: Theme.textMuted
            font { family: Theme.fontMono; pixelSize: 9 }
        }
    }

    // ── EXPANDIDO: redes conhecidas/visíveis (clique conecta) ──
    //  Começa abaixo da linha da LAN (que pode ter altura 0)
    ListView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: lanRow.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        clip: true
        spacing: 2
        opacity: root.lateReveal
        visible: opacity > 0 && root.passSsid === ""
        model: root.networks

        Text {
            anchors.centerIn: parent
            visible: root.networks.length === 0
            text: root.on ? "Nenhuma rede" : "Wi-Fi desligado"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        delegate: Item {
            id: netItem

            required property var modelData

            width: ListView.view.width
            height: 22

            // Mira
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: netHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            // Accent = conectado
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.right: pctText.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: netItem.modelData.name
                color: netItem.modelData.connected ? Theme.accent : Theme.textSecondary
                elide: Text.ElideRight
                font { family: Theme.fontDisplay; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Text {
                id: pctText

                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(netItem.modelData.signalStrength * 100)}%`
                color: Theme.textMuted
                font { family: Theme.fontMono; pixelSize: 9 }
            }

            HoverHandler { id: netHover }
            TapHandler {
                onTapped: {
                    const n = netItem.modelData
                    if (n.connected) {
                        n.requestDisconnect()
                    } else if (n.known || n.security === 0) {
                        // conhecida (senha salva) ou aberta: direto
                        n.requestConnect()
                    } else {
                        // protegida e desconhecida: pede a senha
                        root.passSsid = n.name
                        passFocusTimer.restart()
                    }
                }
            }
        }
    }
}
