import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../Components"

// ═══════════════════════════════════════════
//  BLUETOOTH WIDGET — O adapter e os dispositivos.
//  Idle: ícone (toggle do adapter) + conectados.
//  Expandido: lupa (descoberta), app externo e lista de dispositivos
//  (clique conecta/desconecta).
//  Tamanhos: normal/big (default normal → normal, pra baixo).
//  TODO optionsBluetooth: diálogo de confirmação/pairing quando o
//  dispositivo pedir (sem prioridade por enquanto).
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "bluetooth"
    sizeIdle: "normal"   // Small and Normal
    sizeExpand: "normal" // Normal and Big
    expandDir: "down"    // down, down-left and down-right

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devices: Bluetooth.devices.values
    readonly property var connectedDevs: devices.filter(d => d.connected)

    // ── HEADER: ícone (clique alterna o adapter, com mira) + dado ──
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
                text: {
                    if (!root.on) return "󰂲"
                    return root.connectedDevs.length > 0 ? "󰂱" : "󰂯"
                }
                color: root.expanded ? Theme.accent : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 16 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            HoverHandler { id: iconHover }
            TapHandler {
                onTapped: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled
                }
            }
        }

        // Dado: conectados ("…" quando não cabe; some ao expandir)
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.connectedDevs.map(d => d.name).join(", ")
            color: Theme.textSecondary
            width: Math.min(implicitWidth, 58)
            elide: Text.ElideRight
            opacity: 1 - root.lateReveal
            visible: opacity > 0
            font { family: Theme.fontDisplay; pixelSize: 10 }
        }

        // ── EXPANDIDO: lupa (descoberta) + app, no lugar do dado ──
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
                    // Accent enquanto está descobrindo dispositivos
                    color: (root.adapter?.discovering ?? false)
                        ? Theme.accent
                        : (scanHover.hovered ? Theme.textPrimary : Theme.textMuted)
                    font { family: Theme.fontIcon; pixelSize: 12 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: scanHover }
                TapHandler {
                    onTapped: {
                        if (root.adapter)
                            root.adapter.discovering = !root.adapter.discovering
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
                    onTapped: Quickshell.execDetached([Config.bluetoothApp])
                }
            }
        }
    }

    // ── EXPANDIDO (para baixo): dispositivos ──
    ListView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 134
        clip: true
        spacing: 2
        opacity: root.lateReveal
        visible: opacity > 0
        model: root.devices

        // Vazio: aviso sutil
        Text {
            anchors.centerIn: parent
            visible: root.devices.length === 0
            text: root.on ? "Nenhum dispositivo" : "Bluetooth desligado"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        delegate: Item {
            id: devItem

            required property var modelData

            width: ListView.view.width
            height: 22

            // Mira: fundo sutil sob o item mirado
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: devHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            // Accent = conectado (clique conecta/desconecta)
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                text: devItem.modelData.name
                color: devItem.modelData.connected ? Theme.accent : Theme.textSecondary
                elide: Text.ElideRight
                font { family: Theme.fontDisplay; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            HoverHandler { id: devHover }
            TapHandler {
                onTapped: {
                    if (devItem.modelData.connected)
                        devItem.modelData.disconnect()
                    else
                        devItem.modelData.connect()
                }
            }
        }
    }
}
