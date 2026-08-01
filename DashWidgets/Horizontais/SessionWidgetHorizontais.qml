import QtQuick
import "../../Components"
import "../../Services"

// ═══════════════════════════════════════════
//  SESSION WIDGET (HORIZONTAL) — Bloquear, sair, suspender,
//  reiniciar e desligar. Idle: SÓ o ícone (small é o único tamanho
//  idle). Expandido: os cinco botões deslizam pra dentro e a legenda
//  da ação mirada aparece ao lado. As ações moram em
//  Services/SessionService.qml (as mesmas do app Session).
//
//  TODO: `expandDir: "left"` briga com o conteúdo, que é montado da
//  esquerda pra direita (ícone → legenda → botões). Crescendo pra
//  ESQUERDA a borda recua e leva o ícone junto, tirando-o de onde
//  estava no idle; com "right" ele ficaria parado e os botões é que
//  entrariam. O vertical usa "right". Decidir ao testar.
//
//  Variante horizontal — a vertical está em
//  DashWidgets/Verticais/SessionWidgetVerticais.qml. Registre UMA na
//  Dashboard: mesmo `name`, então compartilham pin/posição
//  persistidos.
//
//  Tamanhos: idle small (único); expande normal/big (default big).
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "session"
    sizeIdle: "small"  // Small
    sizeExpand: "big"  // Normal and Big
    expandDir: "left" // left

    // Ação mirada (pra legenda); -1 = nenhuma
    property int hoverIndex: -1

    // ── ESQUERDA: ícone; a legenda da ação mirada é o dado
    //  (só existe expandido — idle é ícone puro, centrado) ──
    Text {
        id: sessIcon

        anchors.left: parent.left
        // No idle small o ícone centraliza no quadradinho; expandido
        // ele ancora à esquerda (o driver anima entre os dois)
        anchors.leftMargin: (parent.width - width) / 2 * (1 - root.reveal)
        anchors.verticalCenter: parent.verticalCenter
        text: "󰐥"
        color: root.expanded ? Theme.accent : Theme.textMuted
        font { family: Theme.fontIcon; pixelSize: 16 }
        Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
    }

    Text {
        anchors.left: sessIcon.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.hoverIndex >= 0
            ? SessionService.actions[root.hoverIndex].label
            : ""
        color: Theme.textPrimary
        // Até onde os botões deixam (nunca por baixo deles)
        width: Math.max(0, actions.x - sessIcon.width - 16)
        elide: Text.ElideRight
        opacity: root.lateReveal
        visible: opacity > 0
        font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
    }

    // ── DIREITA: os cinco botões (aparecem com a expansão) ──
    Row {
        id: actions

        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        opacity: root.lateReveal
        visible: opacity > 0

        Repeater {
            model: SessionService.actions

            Item {
                id: act

                required property var modelData
                required property int index

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

                HoverHandler {
                    id: actHover
                    onHoveredChanged: {
                        if (hovered)
                            root.hoverIndex = act.index
                        else if (root.hoverIndex === act.index)
                            root.hoverIndex = -1
                    }
                }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: SessionService.run(act.modelData.id)
                }
            }
        }
    }
}
