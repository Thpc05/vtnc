import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import ".."
import "../../Config"
import "../../Services"
import "../../Ui"

// ═══════════════════════════════════════════
//  MEDIA WIDGET — O player.
//  Idle: ícone (toggle) + visualizer + faixa atual.
//  Expandido: capa, artista, controles, onda de progresso e o
//  seletor de fonte (players MPRIS). Tudo via MediaService.
//  Tamanhos: normal/big/full (default big); expande pra baixo.
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "media"
    sizeIdle: "big"    // Normal, Big and Full
    sizeExpand: "big"  // Big and Full
    expandDir: "down"  // down

    // Menu de seleção de fonte aberto?
    property bool sourceMenu: false
    onExpandedChanged: if (!expanded) sourceMenu = false

    // ── FUNDO: capa em blur, clipada no radius do widget ──
    // Overscan de -24: a borda macia que o blur cria (misturando com
    // o transparente fora da imagem) cai FORA do clip — sem halo
    background: ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: MediaService.artUrl !== ""

        Image {
            id: bgArt

            anchors.fill: parent
            anchors.margins: -24
            source: MediaService.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false // só a versão com blur aparece
        }

        MultiEffect {
            anchors.fill: parent
            anchors.margins: -24
            source: bgArt
            blurEnabled: true
            blur: Theme.widgetMediaBlur
            blurMax: 32
            opacity: 0.55
        }

        // Véu escuro: mantém o texto legível sobre qualquer capa
        Rectangle {
            anchors.fill: parent
            color: "#73000000"
        }
    }

    // ── HEADER: ícone (toggle) + visualizer + faixa atual +
    //  seletor de fonte (alinhado com o título, na mesma linha) ──
    Item {
        id: headerRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerH

        Item {
            id: mediaIconBox

            width: 24
            height: 22
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: mediaIconHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Text {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "󰝚" : "󰝛"
                color: root.expanded ? Theme.accent : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 16 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            HoverHandler { id: mediaIconHover }
            TapHandler { onTapped: MediaService.toggle() }
        }

        // Visualizer (só aparece tocando — width própria anima)
        Visualizer {
            id: headerVis
            anchors.left: mediaIconBox.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.left: headerVis.visible ? headerVis.right : mediaIconBox.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            // Abre espaço pro chip conforme ele aparece (expandido)
            anchors.rightMargin: (srcChip.width + 8) * srcChip.opacity
            anchors.verticalCenter: parent.verticalCenter
            text: MediaService.hasPlayer
                ? (MediaService.title !== "" ? MediaService.title : "Mídia")
                : "Sem mídia"
            color: Theme.textPrimary
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
        }

        // ── CHIP da fonte: ícone + nome do app, na linha do título.
        //  Clique abre o popup de troca (só existe com >1 player) ──
        Item {
            id: srcChip

            width: chipContent.implicitWidth + 12
            height: 18
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.lateReveal * (MediaService.hasChoice ? 1 : 0)
            visible: opacity > 0

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusChip
                color: srcHover.hovered || root.sourceMenu ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Row {
                id: chipContent

                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.sourceIcon(MediaService.active)
                    color: root.sourceMenu ? Theme.accent
                        : (srcHover.hovered ? Theme.textPrimary : Theme.textMuted)
                    font { family: Theme.fontIcon; pixelSize: 12 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.sourceName(MediaService.active)
                    color: root.sourceMenu ? Theme.accent
                        : (srcHover.hovered ? Theme.textPrimary : Theme.textSecondary)
                    width: Math.min(implicitWidth, 72)
                    elide: Text.ElideRight
                    font { family: Theme.fontDisplay; pixelSize: 10 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
            }

            HoverHandler { id: srcHover }
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.sourceMenu = !root.sourceMenu
            }
        }
    }

    // ── EXPANDIDO: capa + artista + controles + onda ──
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 116
        opacity: root.lateReveal
        visible: opacity > 0

        // Capa (com fallback pra fontes sem arte válida)
        MediaArt {
            id: cover

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            width: 56
            height: 56
            source: MediaService.artUrl
        }

        // Artista
        Text {
            anchors.left: cover.right
            anchors.leftMargin: 10
            anchors.right: controls.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            text: MediaService.artist
            color: Theme.textSecondary
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        // Controles
        Row {
            id: controls

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            spacing: 8

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: prevHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: prevHover.hovered ? Theme.textPrimary : Theme.textSecondary
                    font { family: Theme.fontIcon; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: prevHover }
                TapHandler { onTapped: MediaService.previous() }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: playHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                    color: playHover.hovered ? Theme.accent : Theme.textPrimary
                    font { family: Theme.fontIcon; pixelSize: 19 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: playHover }
                TapHandler { onTapped: MediaService.toggle() }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusChip
                    color: nextHover.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: nextHover.hovered ? Theme.textPrimary : Theme.textSecondary
                    font { family: Theme.fontIcon; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                HoverHandler { id: nextHover }
                TapHandler { onTapped: MediaService.next() }
            }
        }

        // Onda de progresso (estilo ambxst)
        MediaWave {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 14
            progress: MediaService.progress
            playing: MediaService.isPlaying
        }
    }

    // ── POPUP do seletor: sem borda (como os painéis dos reveals),
    //  centralizado com o chip. O ATUAL fica no topo, um separator
    //  abaixo dele, e então as outras fontes (clique troca) ──
    Rectangle {
        id: srcMenuPop

        width: 150
        height: menuCol.implicitHeight + 12
        radius: 10
        color: Theme.bg
        z: 7
        // Centralizado com o chip, preso às bordas do widget
        x: Math.max(0, Math.min(
            headerRow.x + srcChip.x + srcChip.width / 2 - width / 2,
            parent.width - width))
        anchors.top: headerRow.bottom
        anchors.topMargin: 4
        opacity: root.sourceMenu && root.lateReveal > 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.instant } }

        Column {
            id: menuCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            // Fonte ATUAL (accent; clique só fecha)
            Item {
                width: parent.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.sourceIcon(MediaService.active)
                    color: Theme.accent
                    font { family: Theme.fontIcon; pixelSize: 12 }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.sourceName(MediaService.active)
                    color: Theme.accent
                    elide: Text.ElideRight
                    font { family: Theme.fontDisplay; pixelSize: 11 }
                }

                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: root.sourceMenu = false
                }
            }

            // Separator entre o atual e as opções
            Rectangle {
                width: parent.width - 8
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.surface
            }

            // As OUTRAS fontes (clique troca)
            Repeater {
                model: MediaService.players.filter(p => p !== MediaService.active)

                Item {
                    id: srcItem

                    required property var modelData

                    width: menuCol.width
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusChip
                        color: itemHover.hovered ? Theme.hoverLayer : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: MediaService.sourceIcon(srcItem.modelData)
                        color: itemHover.hovered ? Theme.textPrimary : Theme.textSecondary
                        font { family: Theme.fontIcon; pixelSize: 12 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 26
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: MediaService.sourceName(srcItem.modelData)
                        color: itemHover.hovered ? Theme.textPrimary : Theme.textSecondary
                        elide: Text.ElideRight
                        font { family: Theme.fontDisplay; pixelSize: 11 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    HoverHandler { id: itemHover }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: {
                            MediaService.select(srcItem.modelData)
                            root.sourceMenu = false
                        }
                    }
                }
            }
        }
    }
}
