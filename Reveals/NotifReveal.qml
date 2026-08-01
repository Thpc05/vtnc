import QtQuick
import "../Components"
import "../Services"

// ═══════════════════════════════════════════
//  NOTIF REVEAL — Sino com ponto accent quando há histórico.
//  Mirar revela o painel scrollável de notificações.
//
//  Notificação chegando abre o painel sozinha por alguns segundos:
//  ela nasce no canto de quem é dela — o sino — e o histórico já
//  está ali junto.
// ═══════════════════════════════════════════
Reveal {
    id: root

    name: "notifs"
    panelWidth: 340 // largura natural na bolha da framed

    readonly property int count: NotifServer.history.count

    Connections {
        target: NotifServer
        function onNotified() {
            root.autoShow = true
            autoHideTimer.restart()
        }
    }
    Timer {
        id: autoHideTimer
        interval: Config.notifyTimeout
        onTriggered: root.autoShow = false
    }
    // Mirou enquanto estava aberta? O hover assume e o auto-hide sai
    // da frente (senão o painel sumia com o mouse em cima dele)
    onPanelHoveredChanged: if (panelHovered) {
        autoHideTimer.stop()
        autoShow = false
    }

    panelHovered: panelHover.hovered
    // Suavizada: itens removidos/expandidos encolhem a barra sem
    // degraus (+26 = linha do "Limpar" no topo + respiro embaixo)
    panelHeight: count > 0
        ? Math.min(historyList.contentHeight, Theme.notifHistoryMaxHeight) + 26
        : 26
    Behavior on panelHeight {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // ── ANCHOR: sino + ponto accent ──
    Text {
        text: "󰂚"
        color: root.revealed ? Theme.textPrimary : Theme.textSecondary
        font { family: Theme.fontIcon; pixelSize: 14 }
        Behavior on color { ColorAnimation { duration: Theme.hoverFade } }

        Rectangle {
            visible: root.count > 0
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -2
            anchors.topMargin: -1
        }
    }

    // ── PANEL: histórico scrollável ──
    panel: Item {
        implicitHeight: root.panelHeight

        Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

        HoverHandler { id: panelHover }

        // Vazio: só um aviso sutil
        Text {
            anchors.centerIn: parent
            visible: root.count === 0
            text: "Sem notificações"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        // "Limpar" no TOPO: embaixo ele dançava quando a última
        // notificação expandia no hover — impossível de clicar
        Item {
            anchors.top: parent.top
            anchors.right: parent.right
            width: clearText.implicitWidth + 14
            height: 18
            visible: root.count > 0

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: clearHover.hovered ? Theme.hoverLayer : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
            }

            Text {
                id: clearText

                anchors.centerIn: parent
                text: "Limpar"
                color: clearHover.hovered ? Theme.textPrimary : Theme.textMuted
                font { family: Theme.fontDisplay; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
            }

            HoverHandler { id: clearHover }
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: NotifServer.clearHistory()
            }
        }

        ListView {
            id: historyList

            anchors.top: parent.top
            anchors.topMargin: 22
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(contentHeight, Theme.notifHistoryMaxHeight)
            model: NotifServer.history
            clip: true
            spacing: 0

            // Saída: desliza pra direita sumindo (X ou "Limpar" em cascata)
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 140 }
                    NumberAnimation { property: "x"; to: 80; duration: 140; easing.type: Easing.InCubic }
                }
            }
            // Os itens restantes sobem suavemente pra ocupar o espaço
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 150; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: histItem

                required property int index
                required property string summary
                required property string body
                required property string appName
                required property string time

                readonly property bool hov: itemHover.hovered

                width: historyList.width
                // Mirando: expande pra baixo até caber todo o conteúdo
                height: hov ? Math.max(44, histCol.implicitHeight + 16) : 44
                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                HoverHandler { id: itemHover }

                Column {
                    id: histCol

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: rightCol.left
                    anchors.rightMargin: 8
                    spacing: 1

                    Text {
                        text: histItem.summary !== "" ? histItem.summary : histItem.appName
                        color: Theme.textPrimary
                        width: parent.width
                        wrapMode: histItem.hov ? Text.Wrap : Text.NoWrap
                        elide: histItem.hov ? Text.ElideNone : Text.ElideRight
                        font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
                    }

                    Text {
                        visible: histItem.body !== ""
                        text: histItem.body
                        color: Theme.textSecondary
                        width: parent.width
                        wrapMode: histItem.hov ? Text.Wrap : Text.NoWrap
                        elide: histItem.hov ? Text.ElideNone : Text.ElideRight
                        font { family: Theme.fontDisplay; pixelSize: 11 }
                    }
                }

                Column {
                    id: rightCol

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        anchors.right: parent.right
                        text: histItem.time
                        color: Theme.textMuted
                        font { family: Theme.fontMono; pixelSize: 10 }
                    }

                    // X pra excluir — aparece embaixo da hora ao mirar
                    Item {
                        anchors.right: parent.right
                        width: 18
                        height: 16
                        visible: histItem.hov

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: xHover.hovered ? Theme.hoverLayer : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: xHover.hovered ? Theme.danger : Theme.textMuted
                            font { family: Theme.fontIcon; pixelSize: 11 }
                            Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                        }

                        HoverHandler { id: xHover }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: NotifServer.history.remove(histItem.index)
                        }
                    }
                }
            }
        }
    }
}
