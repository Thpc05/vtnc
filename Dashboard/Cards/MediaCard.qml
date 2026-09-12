import QtQuick
import QtQuick.Effects
import ".."
import "../../Config"
import "../../Services"
import "../../Ui"

// ═══════════════════════════════════════════
//  MEDIA CARD — O card alto do Control Center: capa borrada ao
//  fundo, capa nítida pequena, faixa/artista e os controles.
//
//  O fundo é a PRÓPRIA capa borrada, não uma cor: é o que dá a cada
//  música um card diferente sem precisar extrair paleta nenhuma.
//  Por cima vai um véu preto, senão o texto some em capa clara.
// ═══════════════════════════════════════════
DashCard {
    id: root

    readonly property bool temPlayer: MediaService.hasPlayer

    // O corpo do card alterna play/pause — o gesto mais provável
    onTapped: if (temPlayer) MediaService.toggle()

    // ── FUNDO: capa borrada, sangrando até a borda ──
    // Fora do host de conteúdo (que tem margem) e com z negativo
    Item {
        z: -1
        anchors.fill: parent

        MediaArt {
            id: capaFundo
            anchors.fill: parent
            radius: 0
            source: MediaService.artUrl
            visible: false // só serve de fonte pro blur
        }

        MultiEffect {
            anchors.fill: parent
            source: capaFundo
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            // O mesmo knob do widget antigo, agora vindo do config app
            opacity: Theme.widgetMediaBlur
            visible: MediaService.artUrl !== ""
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
                font { family: Theme.fontIcon; pixelSize: 26 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nada tocando"
                color: Theme.textMuted
                font { family: Theme.fontDisplay; pixelSize: 11 }
            }
        }

        // ── COM MÚSICA ──
        Column {
            anchors.fill: parent
            spacing: 10
            visible: root.temPlayer

            Row {
                width: parent.width
                spacing: 10

                MediaArt {
                    id: capa
                    width: 46
                    height: 46
                    radius: Theme.radiusChip
                    source: MediaService.artUrl
                    glyphSize: 16
                }

                Column {
                    width: parent.width - capa.width - parent.spacing
                    anchors.verticalCenter: capa.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: MediaService.title || "—"
                        elide: Text.ElideRight
                        color: Theme.textPrimary
                        font { family: Theme.fontDisplay; pixelSize: 13; weight: 600 }
                    }
                    Text {
                        width: parent.width
                        text: MediaService.artist
                        elide: Text.ElideRight
                        color: Theme.textSecondary
                        font { family: Theme.fontDisplay; pixelSize: 11 }
                    }
                }
            }

            MediaWave {
                width: parent.width
                height: 14
                progress: MediaService.progress
                playing: MediaService.isPlaying
            }

            // ── CONTROLES ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Hoverable {
                    id: btAnterior
                    width: 34; height: 30
                    onTapped: MediaService.previous()
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: btAnterior.hovered ? Theme.textPrimary : Theme.textSecondary
                        font { family: Theme.fontIcon; pixelSize: 16 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }
                }

                Hoverable {
                    id: btPlay
                    width: 40; height: 30
                    onTapped: MediaService.toggle()
                    Text {
                        anchors.centerIn: parent
                        text: MediaService.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.accent
                        font { family: Theme.fontIcon; pixelSize: 19 }
                    }
                }

                Hoverable {
                    id: btProximo
                    width: 34; height: 30
                    onTapped: MediaService.next()
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: btProximo.hovered ? Theme.textPrimary : Theme.textSecondary
                        font { family: Theme.fontIcon; pixelSize: 16 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }
                }
            }
        }

        // ── SELETOR DE FONTE — só aparece com mais de um player ──
        Hoverable {
            id: chipFonte

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 26
            height: 20
            visible: MediaService.hasChoice
            onTapped: MediaService.cycle()

            Text {
                anchors.centerIn: parent
                text: MediaService.sourceIcon(MediaService.active)
                color: chipFonte.hovered ? Theme.textPrimary : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 12 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }
    }
}
