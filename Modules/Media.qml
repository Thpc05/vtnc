import QtQuick
import "../Components"
import "../Services"

// ═══════════════════════════════════════════
//  MEDIA — Painel do MediaReveal: capa + título/artista + onda de
//  progresso + seletor de fonte. Tudo vem do MediaService (a mesma
//  fonte do MediaWidget da dashboard), então trocar o player num
//  lugar troca em todos.
//
//  Módulo puro: quem hospeda controla opacity/visible.
// ═══════════════════════════════════════════
Row {
    id: root

    spacing: 12

    // Capa (com fallback pra fontes sem arte válida)
    MediaArt {
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 42
        source: MediaService.artUrl
        glyphSize: 16
    }

    // Info + onda
    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: 190
        spacing: 3

        // Título (com visualizer à esquerda) + chip de fonte à direita
        Item {
            width: parent.width
            height: 16

            Row {
                id: titleRow
                anchors.left: parent.left
                anchors.right: srcChip.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Visualizer { anchors.verticalCenter: parent.verticalCenter }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.hasPlayer
                        ? (MediaService.title !== "" ? MediaService.title : "Mídia")
                        : "Sem mídia"
                    color: Theme.textPrimary
                    width: Math.min(implicitWidth, titleRow.width - 22)
                    elide: Text.ElideRight
                    font { family: Theme.fontDisplay; pixelSize: 13; weight: 650 }
                }
            }

            // Seletor de fonte: clique CICLA entre os players (só >1)
            Item {
                id: srcChip
                width: 20
                height: 16
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                opacity: MediaService.hasChoice ? 1 : 0
                visible: opacity > 0

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: chipHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: MediaService.sourceIcon(MediaService.active)
                    color: chipHover.hovered ? Theme.textPrimary : Theme.textMuted
                    font { family: Theme.fontIcon; pixelSize: 12 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: chipHover }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: MediaService.cycle()
                }
            }
        }

        // Artista
        Text {
            text: MediaService.artist
            color: Theme.textSecondary
            width: parent.width
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        // Onda de progresso
        MediaWave {
            width: parent.width
            height: 12
            progress: MediaService.progress
            playing: MediaService.isPlaying
        }
    }
}
