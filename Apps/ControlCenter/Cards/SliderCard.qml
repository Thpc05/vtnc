import QtQuick
import ".."
import "../../../ConfigValues"
import "../../../Ui"

// ═══════════════════════════════════════════
//  SLIDER CARD — Brilho e som.
//
//  A forma: rótulo em cima, TRILHO embaixo. O trilho é uma pílula
//  escura e o preenchimento é outra pílula ENCAIXADA dentro dela, com
//  folga nos quatro lados.
//
//  A primeira versão fazia o card INTEIRO ser a barra, com o
//  preenchimento sangrando de borda a borda. Parecia um bloco de cor
//  cortado em dois: o preenchimento herdava o canto do card de um lado
//  e ficava reto do outro, e não havia como dizer onde o controle
//  começa. Com trilho e preenchimento separados, os dois são pílulas
//  inteiras e o controle se lê como um objeto.
//
//  O ícone mora DENTRO do preenchimento, à esquerda — some junto com
//  ele quando o valor chega perto de zero, o que é a leitura certa:
//  não há o que iluminar num brilho zerado.
// ═══════════════════════════════════════════
ControlCard {
    id: root

    property string label: ""
    property string icon: ""
    property real value: 0
    // Só o ícone muda quando mudo; o valor continua o que era
    property bool muted: false

    signal commit(real v)

    // Altura do trilho. Generoso de propósito: o alvo é a barra toda,
    // não uma linha fina
    readonly property real trackH: 26
    // Folga do preenchimento dentro do trilho
    readonly property real inset: 3

    function _apply(px) {
        // O valor é medido sobre o CURSO ÚTIL (trilho menos as folgas),
        // senão arrastar até a ponta não chegaria a 100%
        const util = trilho.width - inset * 2
        root.commit(Math.max(0, Math.min(1, (px - inset) / util)))
    }

    Item {
        anchors.fill: parent

        Text {
            id: rotulo

            anchors.left: parent.left
            anchors.top: parent.top
            text: root.label
            color: Theme.textPrimary
            font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
        }

        Rectangle {
            id: trilho

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.trackH
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.06)

            Rectangle {
                id: preenchimento

                x: root.inset
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height - root.inset * 2
                // Piso na própria altura: abaixo disso a pílula vira uma
                // lasca e o canto arredondado se desfaz
                width: Math.max(height,
                    (parent.width - root.inset * 2)
                    * Math.max(0, Math.min(1, root.value)))
                radius: height / 2
                color: root.muted ? Theme.textMuted : Theme.accent
                Behavior on color { ColorAnimation { duration: Motion.instant } }
                // Sem Behavior na largura: arrastar tem que colar no
                // cursor. Um Behavior aqui faria a barra perseguir o dedo

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon
                    color: Theme.bg
                    font { family: Theme.fontIcon; pixelSize: 13 }
                    // Some quando o preenchimento fica estreito demais
                    // pra ele caber sem encostar na borda
                    opacity: preenchimento.width > 30 ? 1 : 0
                    Behavior on opacity { Smooth { duration: Motion.instant } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => root._apply(mouse.x)
                onPositionChanged: mouse => { if (pressed) root._apply(mouse.x) }
            }
        }
    }
}
