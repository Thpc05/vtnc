import QtQuick
import "../Components"
import "../Modules"
import "../Services"

// ═══════════════════════════════════════════
//  BATTERY REVEAL — A bateria de emergência ao lado do relógio
//  (aparece < Config.batteryWarnLevel) é o anchor; mirar revela
//  nível, estado e estimativa de tempo.
// ═══════════════════════════════════════════
Reveal {
    id: root

    name: "battery"
    panelWidth: 240 // largura natural na bolha da framed

    panelHovered: panelHover.hovered

    clip: true
    // Largura EXATA do ícone: o respiro é do Row do cluster (spacing),
    // folga aqui vira gap duplo entre o tray e a bateria
    width: BatteryService.low ? bat.implicitWidth : 0
    height: bat.implicitHeight
    opacity: BatteryService.low ? 1 : 0
    // Escondido de verdade quando some — senão o HoverHandler (com
    // margem) ainda dispararia o reveal no meio do cluster
    visible: opacity > 0

    Behavior on width { SmoothedAnimation { duration: 350 } }
    Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

    // ── ANCHOR: a bateria de emergência ──
    Battery {
        id: bat
        anchors.centerIn: parent
    }

    // ── PANEL: detalhes ──
    panel: Item {
        implicitHeight: detailCol.implicitHeight + 8

        Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

        HoverHandler { id: panelHover }

        Column {
            id: detailCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    text: `${BatteryService.charging ? "Carregando" : "Na bateria"} · ${BatteryService.percentage}%`
                    color: Theme.textPrimary
                    font { family: Theme.fontDisplay; pixelSize: 12 }
                }

                Text {
                    anchors.right: parent.right
                    visible: BatteryService.eta !== ""
                    text: BatteryService.eta
                    color: Theme.textSecondary
                    font { family: Theme.fontMono; pixelSize: 11 }
                }
            }

            // Barra de nível
            Rectangle {
                width: parent.width
                height: 5
                radius: 2.5
                color: Theme.surface

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * BatteryService.percentage / 100
                    radius: 2.5
                    // Vermelho pelo MESMO critério do ícone: aviso é
                    // nível baixo sem estar carregando
                    color: BatteryService.warning ? Theme.danger : Theme.accent
                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
