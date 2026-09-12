import QtQuick
import "../../ConfigValues"
import "../../Ui"

// ═══════════════════════════════════════════
//  DETAIL ROW — Uma linha de lista do detalhe: rede, dispositivo
//  bluetooth, saída de áudio. Os três têm a mesma forma, então é um
//  componente só: ícone opcional · nome · valor à direita.
//
//  `current` é "este é o que está em uso" — a rede conectada, a saída
//  ativa. Vira accent, que é como a shell inteira diz "ativo".
// ═══════════════════════════════════════════
Hoverable {
    id: linha

    property string icon: ""
    property string label: ""
    // Texto pequeno à direita: força do sinal, "conectado", vazio
    property string value: ""
    property bool current: false

    radius: Theme.radiusChip
    height: 26
    // A largura vem do Column que hospeda; sem isto a linha some
    width: parent ? parent.width : 0

    Text {
        id: ico

        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: linha.icon !== "" ? 18 : 0
        visible: linha.icon !== ""
        text: linha.icon
        color: linha.current ? Theme.accent : Theme.textMuted
        font { family: Theme.fontIcon; pixelSize: 12 }
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    Text {
        anchors.left: ico.right
        anchors.leftMargin: linha.icon !== "" ? 6 : 0
        anchors.right: valor.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: linha.label
        elide: Text.ElideRight
        color: linha.current ? Theme.accent
             : (linha.hovered ? Theme.textPrimary : Theme.textSecondary)
        font {
            family: Theme.fontDisplay
            pixelSize: 12
            weight: linha.current ? 600 : 400
        }
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    Text {
        id: valor

        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: linha.value
        color: Theme.textMuted
        font { family: Theme.fontMono; pixelSize: 9 }
    }
}
