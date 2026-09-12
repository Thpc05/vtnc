import QtQuick
import QtQuick.Effects
import ".."
import "../../../ConfigValues"
import "../../../Services"
import "../../../Ui"

// ═══════════════════════════════════════════
//  MEDIA CARD — Capa borrada ao fundo, faixa em cima, controles
//  embaixo, e o progresso como uma linha fina na borda inferior.
//
//  O QUE SAIU da primeira versão, e por quê:
//   · a miniatura da capa. O FUNDO já é a capa — mostrar a mesma
//     imagem duas vezes no mesmo card só tirava espaço do título;
//   · a onda (MediaWave). Ela é bonita isolada e barulhenta aqui:
//     uma senoide animada no meio de um Control Center parado puxa o
//     olho pro lugar errado. Virou uma linha de 3px colada na borda —
//     o progresso continua legível e para de competir.
//
//  O play é um DISCO accent e os vizinhos são glyphs sem fundo: a
//  ação principal se acha sem precisar ler os três.
// ═══════════════════════════════════════════
ControlCard {
    id: root

    readonly property bool temPlayer: MediaService.hasPlayer

    // O corpo alterna play/pause — o gesto mais provável
    onTapped: if (temPlayer) MediaService.toggle()

    // ── FUNDO: a capa borrada, sangrando até a borda ──
    Item {
        z: -1
        anchors.fill: parent
        visible: MediaService.artUrl !== ""

        MediaArt {
            id: capa
            anchors.fill: parent
            radius: 0
            source: MediaService.artUrl
            visible: false // só serve de fonte pro blur
        }

        MultiEffect {
            anchors.fill: parent
            source: capa
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            opacity: Theme.widgetMediaBlur
        }

        // Véu: sem ele o texto branco some numa capa clara
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    Item {
        anchors.fill: parent

        // ── SEM MÚSICA ──
        Column {
            anchors.centerIn: parent
            spacing: 6
            visible: !root.temPlayer

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰝚"
                color: Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 24 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nada tocando"
                color: Theme.textMuted
                font { family: Theme.fontDisplay; pixelSize: 11 }
            }
        }

        // ── FAIXA ──
        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 1
            visible: root.temPlayer

            Text {
                width: parent.width
                text: MediaService.title || "—"
                elide: Text.ElideRight
                color: Theme.textPrimary
                font { family: Theme.fontDisplay; pixelSize: 14; weight: 700 }
            }
            Text {
                width: parent.width
                text: MediaService.artist
                elide: Text.ElideRight
                color: Theme.textSecondary
                font { family: Theme.fontDisplay; pixelSize: 11 }
            }
        }

        // ── CONTROLES ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 10
            visible: root.temPlayer

            Hoverable {
                id: btAnterior
                width: 28
                height: 34
                anchors.verticalCenter: parent.verticalCenter
                onTapped: MediaService.previous()

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: btAnterior.hovered ? Theme.textPrimary : Theme.textSecondary
                    font { family: Theme.fontIcon; pixelSize: 15 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
            }

            Rectangle {
                id: btPlay

                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                radius: width / 2
                color: Theme.accent
                // O disco cresce de leve sob o mouse — o feedback de
                // mira aqui é a escala, não um fundo (ele já tem fundo)
                scale: playMira.hovered ? 1.08 : 1
                Behavior on scale { Settle { duration: Motion.instant } }

                Text {
                    anchors.centerIn: parent
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                    color: Theme.bg
                    font { family: Theme.fontIcon; pixelSize: 16 }
                }

                HoverHandler { id: playMira }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: MediaService.toggle()
                }
            }

            Hoverable {
                id: btProximo
                width: 28
                height: 34
                anchors.verticalCenter: parent.verticalCenter
                onTapped: MediaService.next()

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: btProximo.hovered ? Theme.textPrimary : Theme.textSecondary
                    font { family: Theme.fontIcon; pixelSize: 15 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
            }
        }

        // ── SELETOR DE FONTE — só com mais de um player ──
        Hoverable {
            id: chipFonte

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 24
            height: 20
            visible: MediaService.hasChoice
            onTapped: MediaService.cycle()

            Text {
                anchors.centerIn: parent
                text: MediaService.sourceIcon(MediaService.active)
                color: chipFonte.hovered ? Theme.textPrimary : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }
    }

    // ── PROGRESSO: linha colada na borda de baixo ──
    // Fora do host de conteúdo (que tem margem) — ela precisa sangrar
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, MediaService.progress))
        height: 3
        color: Theme.accent
        visible: root.temPlayer
    }
}
