import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../../../ConfigValues"
import "../../../Ui"

// ═══════════════════════════════════════════
//  AUDIO DETAIL — Saída, entrada e o mixer por app.
//
//  A distinção do Pipewire que importa aqui: `isStream` separa o que
//  é DISPOSITIVO (placa, fone) do que é APP tocando. Sem esse filtro
//  a lista de saídas viria cheia de navegador e player.
// ═══════════════════════════════════════════
ControlDetail {
    id: root

    name: "audio"
    title: "Som"

    readonly property var saidas: Pipewire.nodes.values.filter(
        n => n.isSink && !n.isStream && n.audio)
    readonly property var entradas: Pipewire.nodes.values.filter(
        n => !n.isSink && !n.isStream && n.audio)
    // Streams de app: isStream && isSink (o áudio que ELES mandam)
    readonly property var apps: Pipewire.nodes.values.filter(
        n => n.isStream && n.isSink && n.audio)

    // Sem o tracker os volumes/nomes não chegam nem atualizam
    PwObjectTracker {
        objects: [...root.saidas, ...root.entradas, ...root.apps]
    }

    function rotulo(n) {
        return n.nickname || n.description || n.name
    }

    // ── SAÍDA ──
    Column {
        width: parent.width
        spacing: 2

        Text {
            text: "Saída"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 10; weight: 600 }
        }

        Repeater {
            model: root.saidas

            DetailRow {
                required property var modelData

                label: root.rotulo(modelData)
                current: modelData === Pipewire.defaultAudioSink
                icon: "󰓃"
                onTapped: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    // ── ENTRADA ──
    Column {
        width: parent.width
        spacing: 2
        visible: root.entradas.length > 0

        Text {
            text: "Entrada"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 10; weight: 600 }
        }

        Repeater {
            model: root.entradas

            DetailRow {
                required property var modelData

                label: root.rotulo(modelData)
                current: modelData === Pipewire.defaultAudioSource
                icon: "󰍬"
                onTapped: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    // ── MIXER: um slider por app tocando ──
    Column {
        width: parent.width
        spacing: 4
        visible: root.apps.length > 0

        Text {
            text: "Apps"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 10; weight: 600 }
        }

        Repeater {
            model: root.apps

            Item {
                id: appItem

                required property var modelData

                width: parent.width
                height: 34

                readonly property real vol: modelData.audio?.volume ?? 0
                readonly property bool mudo: modelData.audio?.muted ?? false

                Text {
                    id: nomeApp

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.right: parent.right
                    text: root.rotulo(appItem.modelData)
                    elide: Text.ElideRight
                    color: Theme.textSecondary
                    font { family: Theme.fontDisplay; pixelSize: 11 }
                }

                Hoverable {
                    id: btMudo

                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: 20
                    height: 16

                    Text {
                        anchors.centerIn: parent
                        text: appItem.mudo ? "󰝟" : "󰕾"
                        color: appItem.mudo ? Theme.textMuted : Theme.textSecondary
                        font { family: Theme.fontIcon; pixelSize: 11 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    onTapped: {
                        if (appItem.modelData.audio)
                            appItem.modelData.audio.muted = !appItem.modelData.audio.muted
                    }
                }

                Item {
                    id: trilho

                    anchors.left: btMudo.right
                    anchors.leftMargin: 6
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    height: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: height / 2
                        color: Theme.hoverLayer
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Math.max(0, Math.min(1, appItem.vol))
                        height: 5
                        radius: height / 2
                        color: appItem.mudo ? Theme.textMuted : Theme.accent
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6

                        function aplicar(mx) {
                            if (!appItem.modelData.audio)
                                return
                            appItem.modelData.audio.volume =
                                Math.max(0, Math.min(1, mx / trilho.width))
                        }

                        onPressed: mouse => aplicar(mouse.x)
                        onPositionChanged: mouse => { if (pressed) aplicar(mouse.x) }
                    }
                }
            }
        }
    }
}
