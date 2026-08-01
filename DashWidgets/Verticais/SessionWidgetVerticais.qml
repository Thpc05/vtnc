import QtQuick
import "../../Components"
import "../../Services"

// ═══════════════════════════════════════════
//  SESSION WIDGET (VERTICAL) — Bloquear, sair, suspender, reiniciar
//  e desligar, em COLUNA: os cinco botões empilhados já no idle
//  (colunete de meia coluna × 3 linhas). Expandir pro lado revela a
//  legenda de cada ação ao lado do botão. As ações moram em
//  Services/SessionService.qml (as mesmas do app Session).
//
//  Variante vertical — a horizontal está em
//  DashWidgets/Horizontais/SessionWidgetHorizontais.qml. Registre UMA
//  na Dashboard: mesmo `name`, então compartilham pin/posição
//  persistidos.
//
//  Tamanhos: idle small (único); expande normal/big.
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "session"
    orientation: "vertical"
    sizeIdle: "small"    // Small
    sizeExpand: "normal" // Normal and Big
    expandDir: "right"   // left and right

    // Coluna dos botões: centrada no colunete em idle, encosta à
    // esquerda quando expande (as legendas ocupam a direita)
    Column {
        id: stack

        width: 28
        x: (root.width - 24 - width) / 2 * (1 - root.reveal)
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: SessionService.actions

            Item {
                id: act

                required property var modelData

                readonly property bool hovered: actHover.hovered

                width: 28
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: act.hovered ? Theme.hoverLayer : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                }

                Text {
                    anchors.centerIn: parent
                    text: act.modelData.icon
                    color: act.hovered
                        ? (act.modelData.danger ? Theme.danger : Theme.accent)
                        : Theme.textPrimary
                    font { family: Theme.fontIcon; pixelSize: 15 }
                    Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
                }

                // Legenda da ação (aparece com a expansão, ao lado)
                Text {
                    anchors.left: parent.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: act.modelData.label
                    color: act.hovered ? Theme.textPrimary : Theme.textSecondary
                    width: Math.max(0, root.width - 24 - stack.x - 38)
                    elide: Text.ElideRight
                    opacity: root.lateReveal
                    visible: opacity > 0
                    font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
                    Behavior on color { ColorAnimation { duration: Theme.hoverFade } }

                    // Clique na legenda também dispara
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: SessionService.run(act.modelData.id)
                    }
                }

                HoverHandler { id: actHover }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: SessionService.run(act.modelData.id)
                }
            }
        }
    }
}
