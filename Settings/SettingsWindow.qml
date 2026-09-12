import QtQuick
import Quickshell
import "Pages"
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTINGS WINDOW — O app de settings.
//
//  Janela FLUTUANTE normal, não layer-shell: ela é uma janela como
//  qualquer outra, com barra de título do compositor, e não faz parte
//  da shell desenhada na tela.
//
//  Mora DENTRO da mesma instância do quickshell de propósito: assim
//  ela escreve direto nos mesmos singletons que a shell lê, e cada
//  slider mexido reflete AO VIVO na ilha, sem restart e sem ninguém
//  precisar sinalizar recarga. Um app separado teria que reabrir os
//  arquivos e avisar a shell — e a shell teria que escutar.
//
//  Registrar uma página = criar em Pages/ + 1 linha na lista abaixo.
//  Mesmo padrão de Island ↔ IslandFace.
//
//  Abrir:  qs ipc -t settings -c toggle
// ═══════════════════════════════════════════
FloatingWindow {
    id: root

    title: "vtnc — settings"
    implicitWidth: 860
    implicitHeight: 620
    minimumSize.width: 640
    minimumSize.height: 420
    color: Theme.bg

    // ── REGISTRO DE PÁGINAS ──
    readonly property list<Item> pages: [
        aparencia, movimento, ilha, dashboard, comportamento, sistema
    ]
    property int atual: 0

    AppearancePage { id: aparencia }
    MotionPage     { id: movimento }
    IslandPage     { id: ilha }
    DashboardPage  { id: dashboard }
    BehaviorPage   { id: comportamento }
    PathsPage      { id: sistema }

    // As páginas são declaradas soltas acima e reparentadas pro host
    // da rolagem — o mesmo wiring de Island ↔ faces
    Component.onCompleted: {
        for (let i = 0; i < pages.length; i++) {
            const p = pages[i]
            p.parent = paginaHost
            p.width = Qt.binding(() => paginaHost.width)
            p.visible = Qt.binding(() => root.pages[root.atual] === p)
        }
    }

    // ═══ BARRA LATERAL ═══
    Rectangle {
        id: lateral

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 210
        color: Theme.card

        Column {
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 16
            spacing: 4

            Repeater {
                model: root.pages

                Hoverable {
                    id: item

                    required property var modelData
                    required property int index

                    readonly property bool selecionado: root.atual === index

                    width: lateral.width - 20
                    height: 40
                    radius: Theme.radiusCard
                    onTapped: root.atual = index

                    // A seleção é um fundo próprio POR BAIXO da mira do
                    // Hoverable: assim apontar um item já selecionado
                    // ainda dá feedback, em vez de ficar mudo
                    Rectangle {
                        anchors.fill: parent
                        z: -1
                        radius: parent.radius
                        color: item.selecionado ? Theme.hoverLayer : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    Rectangle {
                        id: bolha

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: width / 2
                        color: item.selecionado ? Theme.accent : Theme.hoverLayer
                        Behavior on color { ColorAnimation { duration: Motion.instant } }

                        Text {
                            anchors.centerIn: parent
                            text: item.modelData.icon
                            color: item.selecionado ? Theme.bg : Theme.textSecondary
                            font { family: Theme.fontIcon; pixelSize: 13 }
                            Behavior on color { ColorAnimation { duration: Motion.instant } }
                        }
                    }

                    Text {
                        anchors.left: bolha.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: item.modelData.title
                        elide: Text.ElideRight
                        color: item.selecionado ? Theme.textPrimary : Theme.textSecondary
                        font {
                            family: Theme.fontDisplay
                            pixelSize: 13
                            weight: item.selecionado ? 600 : 400
                        }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }
                }
            }
        }
    }

    // ═══ CONTEÚDO ═══
    Flickable {
        id: rolagem

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: lateral.right
        anchors.right: parent.right
        clip: true
        contentWidth: width
        contentHeight: paginaHost.height + 48
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: paginaHost

            x: 24
            y: 24
            width: rolagem.width - 48
            // As páginas se sobrepõem no mesmo host; só uma fica
            // visível, e a altura segue a que está à mostra
            height: root.pages[root.atual]
                ? root.pages[root.atual].implicitHeight : 0
        }
    }
}
